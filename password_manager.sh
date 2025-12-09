#!/bin/bash

# パスワードを保存するファイル
PASSWORD_FILE="passwords.txt"

# パスワードを追加する関数
add_password() {
    echo -n "サービス名を入力してください："
    read service_name
    echo -n "ユーザー名を入力してください："
    read user_name
    echo -n "パスワードを入力してください："
    read password

    # ファイルに追記
    echo "${service_name}:${user_name}:${password}" >> "$PASSWORD_FILE"
    echo ""
    echo "パスワードの追加は成功しました。"
}

# パスワードを取得する関数
get_password() {
    echo -n "サービス名を入力してください："
    read service_name

    # ファイルが存在しない場合
    if [ ! -f "$PASSWORD_FILE" ]; then
        echo "そのサービスは登録されていません。"
        return
    fi

    # サービス名で検索
    result=$(grep "^${service_name}:" "$PASSWORD_FILE")

    if [ -z "$result" ]; then
        echo "そのサービスは登録されていません。"
    else
        # 結果を解析して表示
        IFS=':' read -r svc usr pwd <<< "$result"
        echo "サービス名：${svc}"
        echo "ユーザー名：${usr}"
        echo "パスワード：${pwd}"
    fi
}

# メイン処理
echo "パスワードマネージャーへようこそ！"

while true; do
    echo -n "次の選択肢から入力してください(Add Password/Get Password/Exit)："
    read choice

    case "$choice" in
        "Add Password")
            add_password
            ;;
        "Get Password")
            get_password
            ;;
        "Exit")
            echo "Thank you!"
            exit 0
            ;;
        *)
            echo "入力が間違えています。Add Password/Get Password/Exit から入力してください。"
            ;;
    esac
    echo ""
done

