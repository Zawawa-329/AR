# AR

# スマホとPCの接続

## PCとiPhoneの接続
1. iPhoneとMacをUSBで接続
    MacとiPhoneどちらも信頼してOK

2. Apple IDの確認
    XCodeを開いた状態でPC上左上のリンゴの横の
    Xcode > Settings > Accounts でAppleIDの追加
    +ボタンで追加(自分のApple Accountで！)

3. プロビジョニングの設定
    XCodeを開き、左上の方にあるファイルマーク
    たくさんファイルが並んでいる、一番上をクリック
    TARGETSの中にある一番上のものをクリック
    Signing & Capabilitiesタブへ移動
    Automatically manage signingにチェック
    Teamを自分のApple IDに設定　なかったらAdd

4. [text](https://developer.apple.com/account) にAppleIDでログイン
    ログインするだけでOK
    Apple Developer Program？が出てくるけど有料なので無視

5. iPhoneを開発者モードに
    設定 > プライバシーとセキュリティ > デベロッパモード
    再起動します

6. 接続できているかの確認
    XCodeを開き、PCの上のメニューから、
    Window > Devices and Simulators
    自分のiPhoneが表示されたらOK！

7. 一回ビルドしてみる
    XCode左のファイルマークを押すとContent Viewがある
    右に何か出てくると思う。右の左下のスマホマークで
    自分のiPhoneを設定
    XCodeの上部のURLバーみたいなやつでも自分のiPhoneに設定
    左上部にある再生マークを押す。多分まだできない
    (どこかでパスワード求められるかもしれない、PCログインのパスワード)

8. 開発アプリの信頼
    スマホの設定 > 一般 > VPNとデバイス管理
    なんか下に出てくるので、自分のものを信頼

9. 完成
    7をもう一回やってみる。XCodeとアプリがスマホに入って
    勝手に出てくるはず！
   

## Gitの基本コマンドを使う

1. `https://github.com/Zawawa-329/AR` を **clone**
   します。 cloneすると、github上のリポジトリを自分のローカルにDownloadできます。
   ```shell
   $ cd <your working spaceなんか好きなファイル>
   $ git clone https://github.com/Zawawa-329/AR
   ```
**:bangbang: 注意**

cloneができたら必ず以下のコマンドを実行してください。
```shell
$ cd AR
$ git config --local core.hooksPath .githooks/ 
```

## XCodeでプログラムを開く

```shell
$ cd AR
$ open AR.xcodeproj
```


## Gitのプルリクエスト(PR)を使う
基本自分の作業は、mainブランチにコミットする前にチームメイトに確認してもらう

1. `(任意の名前)`というブランチを作り、そのブランチに**switch**します
   ```shell
   $ cd <your working space>/AR
   $ git branch pull-request
   $ git switch pull-request
   ```
   今回はpull-requestという名前とします

2. 書き換えた内容を **commit**します
   ```shell
   $ git status # Check your change
   $ git add README.md # README.mdの変更をcommit対象にする
   $ git commit -m "Update github id" # どんな変更を加えたのかを伝えるコメント
   ```
3. 変更内容をgithubに**push**します
   ```shell
   $ git push origin pull-request:pull-request
   ```
4. `https://github.com/Zawawa-329/AR`を開き、**Pull Request**(PR)を作ります。
    - base repository: `Zawawa-329/AR`
    - base branch: `main`
    - target branch: `pull-request`

## PRのレビューをする、PRのレビューをもらう
- PRができたら、チームメイトにそのPRのURLを見てもらいます
- 1人以上に`approve`をもらえたらそのPRをmainブランチにmergeします
- また、チームメイトのPRを開いて **変更内容を確認**し、`approve` しましょう。

---

**:book: Reference**
- [コードレビューの仕方](https://fujiharuka.github.io/google-eng-practices-ja/ja/review/reviewer/)

## 最新の変更をpullする

共同作業中、チームメイトの変更がコミットされたときに

自身のPCの状態を更新する

```bash
git fetch origin
git stash
git merge origin/main
git stash pop
```
git stashとgit stash popは自身の作業中のものを一時保存して更新するもの
一度mainブランチにmergeしてから行うのが理想

```bash
git fetch origin
git checkout origin/main -- path/to/file
```
path/to/fileは特定のものだけpullできる
こっちのがいいと思うけどChatGPTはあんま推奨していなかった
