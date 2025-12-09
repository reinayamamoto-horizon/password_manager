#!/bin/bash

# パスワードを保存するファイル（暗号化されたファイル）
PASSWORD_FILE="passwords.txt.gpg"
TEMP_FILE="/tmp/passwords_temp_$$"

# クリーンアップ関数（一時ファイルを安全に削除）
cleanup() {
    if [ -f "$TEMP_FILE" ]; then
        shred -u "$TEMP_FILE" 2>/dev/null || rm -f "$TEMP_FILE"
    fi
}

# スクリプト終了時にクリーンアップを実行
trap cleanup EXIT

# パスワードを追加する関数
add_password() {
    echo -n "サービス名を入力してください："
    read service_name
    echo -n "ユーザー名を入力してください："
    read user_name
    echo -n "パスワードを入力してください："
    read -s password
    echo ""

    # 既存の暗号化ファイルがある場合は復号して一時ファイルに展開
    if [ -f "$PASSWORD_FILE" ]; then
        echo "暗号化ファイルを復号しています..."
        if ! gpg --quiet --batch --yes --decrypt "$PASSWORD_FILE" > "$TEMP_FILE" 2>/dev/null; then
            echo "復号に失敗しました。パスフレーズを確認してください。"
            gpg --decrypt "$PASSWORD_FILE" > "$TEMP_FILE"
            if [ $? -ne 0 ]; then
                cleanup
                return 1
            fi
        fi
    fi

    # 新しいエントリを一時ファイルに追記
    echo "${service_name}:${user_name}:${password}" >> "$TEMP_FILE"

    # 一時ファイルを暗号化して保存
    echo "ファイルを暗号化しています..."
    if gpg --symmetric --cipher-algo AES256 --batch --yes -o "$PASSWORD_FILE" "$TEMP_FILE"; then
        echo ""
        echo "パスワードの追加は成功しました。（暗号化されました）"
    else
        echo "暗号化に失敗しました。"
    fi

    # 一時ファイルを安全に削除
    cleanup
}

# パスワードを取得する関数
get_password() {
    # 暗号化ファイルが存在しない場合
    if [ ! -f "$PASSWORD_FILE" ]; then
        echo "パスワードファイルが存在しません。"
        return
    fi

    echo -n "サービス名を入力してください："
    read service_name

    # 暗号化ファイルを復号してメモリ上で検索（ファイルには保存しない）
    echo "暗号化ファイルを復号しています..."
    decrypted_content=$(gpg --quiet --decrypt "$PASSWORD_FILE" 2>/dev/null)
    
    if [ $? -ne 0 ]; then
        echo "復号に失敗しました。パスフレーズを確認してください。"
        return
    fi

    # サービス名で検索
    result=$(echo "$decrypted_content" | grep "^${service_name}:")

    if [ -z "$result" ]; then
        echo "そのサービスは登録されていません。"
    else
        # 結果を解析して表示
        IFS=':' read -r svc usr pwd <<< "$result"
        echo ""
        echo "サービス名：${svc}"
        echo "ユーザー名：${usr}"
        echo "パスワード：${pwd}"
    fi
    
    # 復号した内容はメモリ上のみ（ファイルは暗号化されたまま）
    echo ""
    echo "※ファイルは暗号化された状態を維持しています"
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

