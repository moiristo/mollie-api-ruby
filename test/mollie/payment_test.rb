require 'helper'

module Mollie
  class PaymentTest < Test::Unit::TestCase
    def test_setting_attributes
      attributes = {
        resource:   "payment",
        id:         "tr_7UhSN1zuXS",
        mode:       "test",
        created_at: "2018-03-20T09:13:37+00:00",
        amount: {
          "value"    => "10.00",
          "currency" => "EUR"
        },
        description:  "My first payment",
        method:       "ideal",
        country_code: "NL",
        metadata: {
          order_id: "12345"
        },
        details:       {
          consumer_name:    "Hr E G H K\u00fcppers en\/of MW M.J. K\u00fcppers-Veeneman",
          consumer_account: "NL53INGB0618365937",
          consumer_bic:     "INGBNL2A"
        },
        status:        "paid",
        paid_at:       "2018-03-20T09:14:37+00:00",
        is_cancelable: false,
        expires_at:    "2018-03-20T09:28:37+00:00",
        locale:        "nl_NL",
        profile_id:    "pfl_QkEhN94Ba",
        sequence_type: "oneoff",
        redirect_url:  "https://webshop.example.org/order/12345",
        webhook_url:   "https://webshop.example.org/payments/webhook",
        _links:        {
          "self" => {
            "href" => "https://api.mollie.com/v2/payments/tr_7UhSN1zuXS",
            "type" => "application/json"
          },
          "checkout" => {
            "href" => "https://www.mollie.com/payscreen/select-method/7UhSN1zuXS",
            "type" => "text/html"
          },
          "settlement" => {
            "href" => "https://webshop.example.org/payment/tr_WDqYK6vllg/settlement",
          },
          "refunds" => {
            "href" => "https://webshop.example.org/payment/tr_WDqYK6vllg/refunds",
            "type" => "text/html"
          }
        }
      }

      payment = Payment.new(attributes)

      assert_equal 'tr_7UhSN1zuXS', payment.id
      assert_equal 'test', payment.mode
      assert_equal Time.parse('2018-03-20T09:13:37+00:00'), payment.created_at
      assert_equal 'paid', payment.status
      assert_equal true, payment.paid?
      assert_equal Time.parse('2018-03-20T09:14:37+00:00'), payment.paid_at
      assert_equal 10.00, payment.amount.value
      assert_equal 'EUR', payment.amount.currency
      assert_equal 'My first payment', payment.description
      assert_equal 'ideal', payment.method
      assert_equal '12345', payment.metadata.order_id
      assert_equal "Hr E G H K\u00fcppers en\/of MW M.J. K\u00fcppers-Veeneman", payment.details.consumer_name
      assert_equal 'NL53INGB0618365937', payment.details.consumer_account
      assert_equal 'INGBNL2A', payment.details.consumer_bic
      assert_equal 'nl_NL', payment.locale
      assert_equal 'NL', payment.country_code
      assert_equal 'pfl_QkEhN94Ba', payment.profile_id
      assert_equal 'https://webshop.example.org/payments/webhook', payment.webhook_url
      assert_equal 'https://webshop.example.org/order/12345', payment.redirect_url
      assert_equal 'https://www.mollie.com/payscreen/select-method/7UhSN1zuXS', payment.checkout_url
    end

    def test_status_open
      assert Payment.new(status: Payment::STATUS_OPEN).open?
      assert !Payment.new(status: 'not-open').open?
    end

    def test_status_canceled
      assert Payment.new(status: Payment::STATUS_CANCELED).canceled?
      assert !Payment.new(status: 'not-canceled').canceled?
    end

    def test_status_expired
      assert Payment.new(status: Payment::STATUS_EXPIRED).expired?
      assert !Payment.new(status: 'not-expired').expired?
    end

    def test_status_paid
      assert Payment.new(status: Payment::STATUS_PAID).paid?
      assert !Payment.new(status: nil).paid?
    end

    def test_status_failed
      assert Payment.new(status: Payment::STATUS_FAILED).failed?
      assert !Payment.new(status: 'not-failed').failed?
    end

    def test_status_pending
      assert Payment.new(status: Payment::STATUS_PENDING).pending?
      assert !Payment.new(status: 'not-pending').pending?
    end

    def test_application_fee
      stub_request(:get, "https://api.mollie.com/v2/payments/tr_WDqYK6vllg")
        .to_return(:status => 200, :body => %{
          {
            "application_fee": {
              "amount": {
                "value": "42.10",
                "currency": "EUR"
              },
              "description": "Example application fee"
            }
          }
        }, :headers => {})

      payment = Payment.get("tr_WDqYK6vllg")
      assert_equal 42.10, payment.application_fee.amount.value
      assert_equal "EUR", payment.application_fee.amount.currency
    end

    def test_list_refunds
      stub_request(:get, "https://api.mollie.com/v2/payments/pay-id/refunds")
        .to_return(:status => 200, :body => %{{"_embedded" : {"refunds" : [{"id":"ref-id", "payment_id":"pay-id"}]}}}, :headers => {})

      refunds = Payment.new(id: "pay-id").refunds.all

      assert_equal "ref-id", refunds.first.id
    end

    def test_create_refund
      stub_request(:post, "https://api.mollie.com/v2/payments/pay-id/refunds")
        .with(body: %{{"amount":{"value":1.95,"currency":"EUR"}}})
        .to_return(:status => 201, :body => %{{"id":"my-id", "amount":{"value": 1.95, "currency": "EUR"}}}, :headers => {})

      refund = Payment.new(id: "pay-id").refunds.create(amount: { value: 1.95, currency: "EUR" })

      assert_equal "my-id", refund.id
      assert_equal BigDecimal.new("1.95"), refund.amount.value
      assert_equal 'EUR', refund.amount.currency
    end

    def test_delete_refund
      stub_request(:delete, "https://api.mollie.com/v2/payments/pay-id/refunds/ref-id")
        .to_return(:status => 204, :headers => {})

      refund = Payment.new(id: "pay-id").refunds.delete("ref-id")
      assert_equal nil, refund
    end

    def test_get_refund
      stub_request(:get, "https://api.mollie.com/v2/payments/pay-id/refunds/ref-id")
        .to_return(:status => 200, :body => %{{"id":"ref-id"}}, :headers => {})

      refund = Payment.new(id: "pay-id").refunds.get("ref-id")

      assert_equal "ref-id", refund.id
    end

    def test_list_chargebacks
      stub_request(:get, "https://api.mollie.com/v2/payments/pay-id/chargebacks")
        .to_return(:status => 200, :body => %{{"_embedded" : {"chargebacks" :[{"id":"chb-id", "payment_id":"pay-id"}]}}}, :headers => {})

      chargebacks = Payment.new(id: "pay-id").chargebacks.all

      assert_equal "chb-id", chargebacks.first.id
    end

    def test_get_chargeback
      stub_request(:get, "https://api.mollie.com/v2/payments/pay-id/chargebacks/chb-id")
        .to_return(:status => 200, :body => %{{"id":"chb-id"}}, :headers => {})

      chargeback = Payment.new(id: "pay-id").chargebacks.get("chb-id")

      assert_equal "chb-id", chargeback.id
    end

    def test_get_settlement
      stub_request(:get, "https://api.mollie.com/v2/payments/tr_WDqYK6vllg")
        .to_return(:status => 200, :body => %{
          {
              "resource": "payment",
              "id": "tr_WDqYK6vllg",
              "settlement_id": "stl_jDk30akdN"
          }
        }, :headers => {})

      stub_request(:get, "https://api.mollie.com/v2/settlements/stl_jDk30akdN")
        .to_return(:status => 200, :body => %{
          {
              "resource": "settlement",
              "id": "stl_jDk30akdN"
          }
        }, :headers => {})

      payment    = Payment.get("tr_WDqYK6vllg")
      settlement = payment.settlement
      assert_equal "stl_jDk30akdN", settlement.id
    end

    def test_nil_settlement
      payment = Payment.new(id: "tr_WDqYK6vllg")
      assert payment.settlement.nil?
    end

    def test_get_mandate
      stub_request(:get, "https://api.mollie.com/v2/payments/tr_WDqYK6vllg")
        .to_return(:status => 200, :body => %{
          {
              "resource": "payment",
              "id": "tr_WDqYK6vllg",
              "mandate_id": "mdt_h3gAaD5zP"
          }
        }, :headers => {})

      stub_request(:get, "https://api.mollie.com/v2/mandates/mdt_h3gAaD5zP")
        .to_return(:status => 200, :body => %{
          {
              "resource": "mandate",
              "id": "mdt_h3gAaD5zP"
          }
        }, :headers => {})

      payment = Payment.get("tr_WDqYK6vllg")
      mandate = payment.mandate
      assert_equal "mdt_h3gAaD5zP", mandate.id
    end

    def test_nil_mandate
      payment = Payment.new(id: "tr_WDqYK6vllg")
      assert payment.mandate.nil?
    end

    def test_get_subscription
      stub_request(:get, "https://api.mollie.com/v2/payments/tr_WDqYK6vllg")
        .to_return(:status => 200, :body => %{
          {
              "resource": "payment",
              "id": "tr_WDqYK6vllg",
              "subscription_id": "sub_rVKGtNd6s3",
              "customer_id": "cst_8wmqcHMN4U"
          }
        }, :headers => {})

      stub_request(:get, "https://api.mollie.com/v2/customers/cst_8wmqcHMN4U/subscriptions/sub_rVKGtNd6s3")
        .to_return(:status => 200, :body => %{
          {
              "resource": "subscription",
              "id": "sub_rVKGtNd6s3"
          }
        }, :headers => {})

      payment = Payment.get("tr_WDqYK6vllg")
      subscription = payment.subscription
      assert_equal "sub_rVKGtNd6s3", subscription.id
    end

    def test_nil_subscription
      payment = Payment.new(id: "tr_WDqYK6vllg")
      assert payment.subscription.nil?

      payment = Payment.new(id: "tr_WDqYK6vllg", customer_id: "cst_8wmqcHMN4U")
      assert payment.subscription.nil?

      payment = Payment.new(id: "tr_WDqYK6vllg", subscription_id: "sub_rVKGtNd6s3")
      assert payment.subscription.nil?
    end

    def test_get_customer
      stub_request(:get, "https://api.mollie.com/v2/payments/tr_WDqYK6vllg")
        .to_return(:status => 200, :body => %{
          {
              "resource": "payment",
              "id": "tr_WDqYK6vllg",
              "customer_id": "cst_8wmqcHMN4U"
          }
        }, :headers => {})

      stub_request(:get, "https://api.mollie.com/v2/customers/cst_8wmqcHMN4U")
        .to_return(:status => 200, :body => %{
          {
              "resource": "customer",
              "id": "cst_8wmqcHMN4U"
          }
        }, :headers => {})

      payment  = Payment.get("tr_WDqYK6vllg")
      customer = payment.customer
      assert_equal "cst_8wmqcHMN4U", customer.id
    end

    def test_nil_customer
      payment = Payment.new(id: "tr_WDqYK6vllg")
      assert payment.customer.nil?
    end
  end
end
