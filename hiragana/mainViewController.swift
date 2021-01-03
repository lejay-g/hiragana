//
//  mainViewController.swift
//  hiragana
//
//  Created by 西田祥子 on 2021/01/02.
//

import UIKit
import Kingfisher

class mainViewController: UIViewController,UITextViewDelegate {

    @IBOutlet weak var originalText: UITextView!
    @IBOutlet weak var convertButton: UIButton!
    @IBOutlet weak var convertButtonView: UIView!
    @IBOutlet weak var hiraganaText: UILabel!
    
    @IBOutlet weak var inputBoxView: UIView!
    @IBOutlet weak var outputBoxView: UIView!
    
    @IBOutlet weak var inputWhiteBoxView: UIView!
    @IBOutlet weak var outputWhiteBoxView: UIView!
    
    @IBOutlet weak var beforeConvertView: UIView!
    @IBOutlet weak var afterConvertView: UIView!
    
    @IBOutlet weak var creditImage: UIImageView!
    
    //入力用文字列保管用
    var input_text:String! = ""

    //ひらがな化API
    let url_string:String! = "https://labs.goo.ne.jp/api/hiragana" //url
    let app_id:String! = "7a3f0555810ef9a28e9f27b76672e86ed09fd9676b37c6990337f0210608fc68" //
    let credit_url_string:String! = "http://u.xgoo.jp/img/sgoo.png" //クレジット用画像URL
    let link_url_string:String! = "https://labs.goo.ne.jp" //リンク先
    
    override func viewDidLoad() {
        super.viewDidLoad()

        //初期設定
        self.set_disp()
        self.set_toolbar()
        
        self.originalText.delegate = self

        //クレジット画像タップ動作セット
        let creditTap = UITapGestureRecognizer(target: self,
                                               action: #selector(creditButtonTapped))
        self.creditImage.addGestureRecognizer(creditTap)
    }
    
    ///キーボードの完了ボタン設定
    func set_toolbar(){
        // ツールバー生成(サイズはsizeToFitメソッドで自動で調整される)
        let toolBar = UIToolbar(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
        // サイズの自動調整(あえて手動で実装したい場合はCGRectに記述してsizeToFitは呼び出さないこと）
        toolBar.sizeToFit()
        // 左側のBarButtonItemはflexibleSpace ※これがないと右に寄らない
        let spacer = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.flexibleSpace,
                                     target: self,
                                     action: nil)
        // Doneボタン
        let commitButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.done,
                                           target: self,
                                           action: #selector(commitButtonTapped))
        // BarButtonItemの配置
        toolBar.items = [spacer, commitButton]
        // キーボードにツールバーを設定
        self.originalText.inputAccessoryView = toolBar
    }
    
    ///パーツ初期設定
    func set_disp(){
        
        self.beforeConvertView.isHidden = false
        self.afterConvertView.isHidden = true
        
        self.convertButtonView.layer.cornerRadius = 30
        self.inputWhiteBoxView.layer.cornerRadius = 10
        self.outputWhiteBoxView.layer.cornerRadius = 10
        
        //クレジット画像セット
        let url = URL(string: self.credit_url_string)
        self.creditImage.kf.setImage(with: url)
        
    }

    /// 変換ボタン
    @IBAction func convertButtonTouchUpInside(_ sender: Any) {
        if self.input_text.count > 0 {
            
            //apiパラメータ設定
            let postdata = postData(app_id: self.app_id,
                                    request_id: "record003",
                                    sentence: self.input_text,
                                    output_type: "hiragana")

            //JSONに変換する
            guard let uploadData = try? JSONEncoder().encode(postdata) else {
                print("json生成に失敗しました")
                return
            }

            var request = URLRequest(url: URL(string: self.url_string)!)
            request.httpMethod = "POST"
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = uploadData
            
            //POST
            let task = URLSession.shared.uploadTask(with: request, from: uploadData) {
                //受信後の処理
                data, response, error in
                if let error = error {
                    print ("error: \(error)")
                    return
                }
                guard let response = response as? HTTPURLResponse,
                    (200...299).contains(response.statusCode) else {
                        print ("server error")
                        return
                }
                if response.statusCode == 200 {
                    guard let data = data, let jsonData = try? JSONDecoder().decode(responseData.self, from: data) else {
                        print("json変換に失敗しました")
                        return
                    }
                    print(jsonData.converted)
                    DispatchQueue.main.async {
                        self.beforeConvertView.isHidden = true
                        self.afterConvertView.isHidden = false
                        self.hiraganaText.text = jsonData.converted
                    }
                } else {
                    print("status code: \(response.statusCode)\n")
                }
            }
            task.resume()
        }
    }
    ///入力部分クリアボタン
    @IBAction func clearButtonTouchUpInside(_ sender: Any) {
        self.originalText.text = ""
        self.hiraganaText.text = ""
        self.afterConvertView.isHidden = true
        self.beforeConvertView.isHidden = false
        
        //textViewにフォーカスする
        self.originalText.becomeFirstResponder()
    }
    
    /// キーボード用doneボタンで入力完了
    @objc func commitButtonTapped() {
        self.view.endEditing(true)
    }
    
    /// クレジット画像タップで外部ブラウザ起動
    @objc func creditButtonTapped() {
        if UIApplication.shared.canOpenURL(URL(string: self.link_url_string)!) {
              UIApplication.shared.open(URL(string: self.link_url_string)!)
        } else {
              print("ブラウザ起動失敗")
        }
    }
    // 入力完了
    func textViewShouldEndEditing(_ textView: UITextView) -> Bool {
        if textView == self.originalText {
            self.input_text = textView.text
        }
        
        return true
    }

}

//リクエストパラメータ
struct postData:Codable {
    //アプリケーションID
    var app_id:String
    //省略時は"labs.goo.ne.jp[タブ文字]リクエスト受付時刻[タブ文字]連番"
    var request_id:String
    //解析対象テキスト
    var sentence:String
    //出力種別：hiragana(ひらがな化)、katakana(カタカナ化)どちらかを指定
    var output_type:String
}

//レスポンスパラメータ
struct responseData:Codable {
    //省略時は"labs.goo.ne.jp[タブ文字]リクエスト受付時刻[タブ文字]連番"
    var request_id:String
    //出力種別
    var output_type:String
    //変換後文字列
    var converted:String
}
