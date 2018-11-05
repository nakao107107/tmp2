require 'peddler'
require 'nokogiri'
require 'yaml'
require 'date'

credentials = YAML.load_file("C:/amazon_txt/config.yml")
time = Time.new
time_str = time.strftime("%Y-%m-%d %H:%M:%S")
today = Date.today
before_day = today-3

client = MWS::Reports::Client.new(
  "marketplace": "JP",
  "aws_access_key_id": credentials["aws_access_key_id"],
  "aws_secret_access_key": credentials["aws_secret_access_key"],
  "merchant_id": credentials["merchant_id"]
)

report_type=[
    "_GET_FLAT_FILE_OPEN_LISTINGS_DATA_",
    "_GET_MERCHANT_LISTINGS_DATA_",
    "_GET_FLAT_FILE_ALL_ORDERS_DATA_BY_ORDER_DATE_",
    "_GET_FBA_MYI_UNSUPPRESSED_INVENTORY_DATA_"
]

file_name = [
    "C:/amazon_txt/data.txt",
    "C:/amazon_txt/data詳細.txt",
    "C:/amazon_txt/data売上.txt",
    "C:/amazon_txt/FBA在庫.txt"
]

report_type_easy = [
    "出品レポート",
    "出品詳細レポート",
    "全注文レポート",
    "FBA在庫管理"
]


report_type.each_with_index do |report_type,i|


    begin
        res = client.get_report_list(report_type_list: [report_type])
    rescue => error
        message = "[#{time_str}] mwsとの通信に失敗しました。出品者情報が正しくない可能性があります。\r\n"
        File.open('C:/amazon_txt/error.log',"a") do |file|
            file << message
            file.close
        end
        exit;
    end
    report_info = res.parse["ReportInfo"]


    if report_info.kind_of?(Array) #複数あった場合

        report_id = report_info[0]["ReportId"]

    elsif report_info.kind_of?(Hash) #単独の場合

        report_id = report_info["ReportId"]
    
    else #そもそもデータがない場合

        if i == 2 #全注文レポートに関してはリクエストを送る
            today = Date.today
            before_day = today-3
            res=client.request_report("_GET_FLAT_FILE_ALL_ORDERS_DATA_BY_ORDER_DATE_",{"start_date":before_day})
            next
        end

        message = "[#{time_str}] #{report_type_easy[i]} が見つかりませんでした\r\n"
        p message
        #error.logへの書き込み
        File.open('C:/amazon_txt/error.log',"a") do |file|
            file << message
            file.close
        end
        next

    end

    if i == 0 #なぜか出品レポートだけ文字化けするので分岐
        res = client.get_report(report_id)
        res = Peddler::Parser.new(res,'utf-8')
    else
        res = client.get_report(report_id)
    end

    File.open(file_name[i],"w",enconding:"utf-8") do |file|
        file << res.parse
        p "[#{time_str}] #{file_name[i]} への書き込みが完了しました"
        file.close
    end
    
end
