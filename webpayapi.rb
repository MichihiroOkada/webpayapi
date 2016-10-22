=begin
WebPay Ruby API ドキュメント: https://webpay.jp/docs/api/ruby
=end
require 'webpay'

#ENABLE_VERBOSE_LOG = true
ENABLE_VERBOSE_LOG = false

# WebPay基本処理のインターフェースクラス
class WebPayApi
  # コンストラクタ
  #
  # === Parameters:
  # key::
  #  WebPayアカウントに紐づく秘密鍵
  #  WebPayとの各通信に利用
  def initialize(key)
    @webpay = WebPay.new(key)
  end

  # カード情報からトークンの作成
  #
  # === Parameters:
  # number::
  #  カード番号
  # month::
  #  カードの有効期限（月）
  # year::
  #  カードの有効期限（年）
  # cvc::
  #  カードのセキュリティコード
  # cvc::
  #  カードの所有者名
  #
  # === Returns:
  # 成功時::
  #   WebPay::TokenResponse インスタンス
  # 失敗時::
  #   WebPay::ErrorResponse インスタンス
  def create_token(number, month, year, cvc, name)
    begin
      token = @webpay.token.create(
          card: 
          {number: "#{number}",
            exp_month: month,
            exp_year: year,
            cvc: "#{cvc}",
            name: "#{name}"}
      )

      p token if ENABLE_VERBOSE_LOG
    rescue WebPay::ErrorResponse::InvalidRequestError => e
      #不適切な値が指定された場合(param: uuid)
      #WebPay Extend 以外からのリクエストで customer が指定された場合
      # (param: customer)
      #customerとcardのどちらも指定されていない、あるいは両方が指定された場合
      # (paramなし)
      #WebPay.jsやCheckoutHelperからのリクエストで改竄など、不正が検出された場合
      # (paramなし)
      puts "[ERROR]create_token InvalidRequest"
      p e
    #rescue WebPay::ErrorResponse::Unauthorized => e
    #  # WebPay.jsやCheckoutHelperからのリクエストで非公開鍵が使われた場合
    #  puts "[ERROR]Unauthorized"
    #  p e
    rescue WebPay::ErrorResponse::CardError => e
      # カード情報が正しく入力されていない場合
      puts "[ERROR]create_token CardError"
      p e
    end

    return token
  end

  # 指定されたカードに課金する
  #
  # === Parameters:
  # token::
  #  課金するカードのトークンのID
  # amount::
  #  課金する金額
  #
  # === Returns:
  # 成功時::
  #   WebPay::ChargeResponse インスタンス
  # 失敗時::
  #   WebPay::ErrorResponse インスタンス
  def create_charge(token_id, amount)
    begin
      charge_response = @webpay.charge.create(
        amount:amount,
        currency: "jpy",
        card: "#{token_id}",
        description: "",
      )

      p charge_response if ENABLE_VERBOSE_LOG
    rescue WebPay::ErrorResponse::InvalidRequestError => e
      # 必須パラメータが指定されていない場合
      # (param: amount, currency)
      # 不適切な値が指定された場合
      # (param: amount, currency, expire_days, uuid)
      # customerとcardのどちらも指定されていない、あるいは両方が指定された場合
      # (paramなし)
      puts "[ERROR]create_charge InvalidRequest"
      p e
    rescue WebPay::ErrorResponse::CardError => e
      # カード情報が正しく入力されていない場合
      puts "[ERROR]create_charge CardError"
      p e
    rescue WebPay::ErrorResponse::NotFound => e
      # 指定されたオブジェクトが存在しない場合(param: customer, shop)
      puts "[ERROR]create_charge NotFound"
      p e
    end

    return charge_response
  end

  # 顧客の作成
  #
  # === Parameters:
  # token::
  #  課金するカードのトークンのID
  # description::
  #  顧客の補足情報
  #
  # === Returns:
  # 成功時::
  #   WebPay::CustomerResponse インスタンス
  # 失敗時::
  #   WebPay::ErrorResponse インスタンス
  def create_customer(token_id, description)
    begin
      customer_response = @webpay.customer.create(
        card: "#{token_id}",
        description: "#{description}",
      )

      p customer_response if ENABLE_VERBOSE_LOG
    rescue WebPay::ErrorResponse::InvalidRequestError => e
      # 不適切な値が指定された場合(param: email, uuid)
      puts "[ERROR]create_customer InvalidRequest"
      p e
    rescue WebPay::ErrorResponse::CardError => e
      # カード情報が正しく入力されていない場合
      puts "[ERROR]create_customer CardError"
      p e
    end

    return customer_response
  end
end

if __FILE__ == $0
  webpay = WebPayApi.new("test_secret_2Yu5Wi9RydeK2oQ3rx0pc8A9")
  #token = webpay.create_token("4242-4242-4242-4242", 8, 2019, "123", "M O")
  token = webpay.create_token("4242", 8, 2019, "123", "M O")
  webpay.create_charge(token.id, 200) unless token.nil?
end

