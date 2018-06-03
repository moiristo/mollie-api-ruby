require 'helper'

module Mollie
  class SettlementTest < Test::Unit::TestCase
    def test_setting_attributes
      attributes = {
        id:         'stl_jDk30akdN',
        reference:  '1234567.1511.03',
        settled_at: '2015-11-06T06:00:02.0Z',
        amount:     { "value" => 39.75, "currency" => "EUR" },
        periods:    {
          "2015" => {
            "11" => {
              revenue: [
                         {
                           description: 'iDEAL',
                           method:      'ideal',
                           count:       6,
                           amount:      {
                             net:   86.1000,
                             vat:   nil,
                             gross: 86.1000
                           }
                         },
                         {
                           description: 'Refunds iDEAL',
                           method:      'refund',
                           count:       2,
                           amount:      {
                             net:   -43.2000,
                             vat:   nil,
                             gross: -43.2000
                           }
                         }
                       ],
              costs:   [
                         {
                           description: 'iDEAL',
                           method:      'ideal',
                           count:       6,
                           rate:        {
                             fixed:      0.3500,
                             percentage: nil
                           },
                           amount:      {
                             net:   2.1000,
                             vat:   0.4410,
                             gross: 2.5410
                           }
                         },
                         {
                           description: 'Refunds iDEAL',
                           method:      'refund',
                           count:       2,
                           rate:        {
                             fixed:      0.2500,
                             percentage: nil
                           },
                           amount:      {
                             net:   0.5000,
                             vat:   0.1050,
                             gross: 0.6050
                           }
                         }
                       ]
            }
          }
        },
        _links: {
          "payments" => {
            "href" => "https://api.mollie.nl/v2/settlements/stl_jDk30akdN/payments",
            "type" => "application/hal+json"
          },
          "refunds" => {
            "href" => "https://api.mollie.nl/v2/settlements/stl_jDk30akdN/refunds",
            "type" => "application/hal+json"
          },
          "chargebacks" => {
            "href" => "https://api.mollie.nl/v2/settlements/stl_jDk30akdN/chargebacks",
            "type" => "application/hal+json"
          }
        },
      }

      settlement = Settlement.new(attributes)

      assert_equal 'stl_jDk30akdN', settlement.id
      assert_equal '1234567.1511.03', settlement.reference
      assert_equal Time.parse('2015-11-06T06:00:02.0Z'), settlement.settled_at
      assert_equal 39.75, settlement.amount

      assert_equal 'iDEAL', settlement.periods[:'2015'][:'11'].revenue[0].description
      assert_equal 'ideal', settlement.periods[:'2015'][:'11'].revenue[0][:method]
      assert_equal 6, settlement.periods[:'2015'][:'11'].revenue[0].count
      assert_equal 86.1, settlement.periods[:'2015'][:'11'].revenue[0].amount.net
      assert_equal nil, settlement.periods[:'2015'][:'11'].revenue[0].amount.vat
      assert_equal 86.1, settlement.periods[:'2015'][:'11'].revenue[0].amount.gross

      assert_equal 'Refunds iDEAL', settlement.periods[:'2015'][:'11'].revenue[1].description
      assert_equal 'refund', settlement.periods[:'2015'][:'11'].revenue[1][:method]
      assert_equal 2, settlement.periods[:'2015'][:'11'].revenue[1].count
      assert_equal -43.2, settlement.periods[:'2015'][:'11'].revenue[1].amount.net
      assert_equal nil, settlement.periods[:'2015'][:'11'].revenue[1].amount.vat
      assert_equal -43.2, settlement.periods[:'2015'][:'11'].revenue[1].amount.gross

      assert_equal 'iDEAL', settlement.periods[:'2015'][:'11'].costs[0].description
      assert_equal 'ideal', settlement.periods[:'2015'][:'11'].costs[0][:method]
      assert_equal 6, settlement.periods[:'2015'][:'11'].costs[0].count
      assert_equal 0.35, settlement.periods[:'2015'][:'11'].costs[0].rate.fixed
      assert_equal nil, settlement.periods[:'2015'][:'11'].costs[0].rate.percentage
      assert_equal 2.1, settlement.periods[:'2015'][:'11'].costs[0].amount.net
      assert_equal 0.441, settlement.periods[:'2015'][:'11'].costs[0].amount.vat
      assert_equal 2.541, settlement.periods[:'2015'][:'11'].costs[0].amount.gross

      assert_equal 'Refunds iDEAL', settlement.periods[:'2015'][:'11'].costs[1].description
      assert_equal 'refund', settlement.periods[:'2015'][:'11'].costs[1][:method]
      assert_equal 2, settlement.periods[:'2015'][:'11'].costs[1].count
      assert_equal 0.25, settlement.periods[:'2015'][:'11'].costs[1].rate.fixed
      assert_equal nil, settlement.periods[:'2015'][:'11'].costs[1].rate.percentage
      assert_equal 0.5, settlement.periods[:'2015'][:'11'].costs[1].amount.net
      assert_equal 0.105, settlement.periods[:'2015'][:'11'].costs[1].amount.vat
      assert_equal 0.605, settlement.periods[:'2015'][:'11'].costs[1].amount.gross

      assert_equal 'https://api.mollie.nl/v2/settlements/stl_jDk30akdN/payments', settlement.payments
      assert_equal 'https://api.mollie.nl/v2/settlements/stl_jDk30akdN/refunds', settlement.refunds
      assert_equal 'https://api.mollie.nl/v2/settlements/stl_jDk30akdN/chargebacks', settlement.chargebacks
    end

    def test_open_settlement
      stub_request(:get, "https://api.mollie.nl/v2/settlements/open")
        .to_return(:status => 200, :body => %{{"id":"set-id"}}, :headers => {})

      settlement = Settlement.open

      assert_kind_of Settlement, settlement
      assert_equal "set-id", settlement.id
    end

    def test_next_settlement
      stub_request(:get, "https://api.mollie.nl/v2/settlements/next")
        .to_return(:status => 200, :body => %{{"id":"set-id"}}, :headers => {})

      settlement = Settlement.next

      assert_kind_of Settlement, settlement
      assert_equal "set-id", settlement.id
    end
  end
end
