//
//  mainViewController.swift
//  hiragana
//
//  Created by 西田祥子 on 2021/01/02.
//

import UIKit

class mainViewController: UIViewController,UITextFieldDelegate {

    @IBOutlet weak var originalText: UITextField!
    @IBOutlet weak var convertButton: UIButton!
    @IBOutlet weak var hiraganaText: UILabel!
    
    //入力用文字列
    var input_text:String! = ""

    //ひらがな化API
    let url_string:String! = "https://labs.goo.ne.jp/api/hiragana" //url
    let api_key:String! = "7a3f0555810ef9a28e9f27b76672e86ed09fd9676b37c6990337f0210608fc68" //
    
    override func viewDidLoad() {
        super.viewDidLoad()


        // キーボードの完了ボタン
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
        
        self.originalText.delegate = self

    }
    
    
    /// 変換ボタン
    @IBAction func convertButtonTouchUpInside(_ sender: Any) {
        if self.input_text.count > 0 {
            
            //パラメータ設定
            let postdata = postData(app_id: self.api_key,
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
                        self.hiraganaText.text = jsonData.converted
                    }
                } else {
                    print("status code: \(response.statusCode)\n")
                }
            }
            task.resume()
            
            
        } else {
            //未入力エラー表示
        }
    }
    
    /// キーボード用doneボタン
    @objc func commitButtonTapped() {
        self.view.endEditing(true)
    }
    

    // 入力完了
    func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
        
        if textField == self.originalText {
            self.input_text = textField.text
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
