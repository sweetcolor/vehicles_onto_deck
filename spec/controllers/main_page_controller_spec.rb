require 'rails_helper'

RSpec.describe MainPageController, :type => :controller do
  describe 'GET #query' do
    it 'responds successfully with an HTTP 200 status code' do
      # NOT WORK!!!
      get :index, params: { query: 'deck_width=5~deck_length=8~stdmax=500~EX_A1:B7=300_E1:E1=200~sv=2,3,100~rv_A,2,3,150_B,3,5,170_C,2,3,150_D,2,3,100~sort_order=L,W,1~placement=UL~a=vis=shc0,0,0,0~LL=3,0,162,232~c=y' }
      assigns(:parsed_query).should([[:deck_width, 5], [:deck_length, 8], [:stdmax, 500], [:EX, {{:width=>0..6, :length=>0..1}=>300, {:width=>0..0, :length=>4..4}=>200}], [:sv, [2, 3, 100]], [:rv, [{:name=>"B", :width=>3, :length=>5, :height=>170}, {:name=>"C", :width=>2, :length=>3, :height=>150}, {:name=>"A", :width=>2, :length=>3, :height=>150}, {:name=>"D", :width=>2, :length=>3, :height=>100}]], [:sort_order, ["L", "W", 1]], [:placement, "UL"], [:a, ["vis", "shc0,0,0,0"]], [:LL, [3, 0, 162, 232]], [:c, "y"], [:SV, [{:name=>:sv, :width=>2, :length=>3, :height=>100}]]])
      # expect(controller.parsed_params).to eq({:deck_width=>5, :deck_length=>8, :stdmax=>500, :EX=>{{:width=>0..6, :length=>0..1}=>300, {:width=>0..0, :length=>4..4}=>200}, :sv=>[2, 3, 100], :rv=>[{:name=>"B", :width=>3, :length=>5, :height=>170}, {:name=>"C", :width=>2, :length=>3, :height=>150}, {:name=>"A", :width=>2, :length=>3, :height=>150}, {:name=>"D", :width=>2, :length=>3, :height=>100}], :sort_order=>["L", "W", 1], :placement=>"UL", :a=>["vis", "shc0,0,0,0"], :LL=>[3, 0, 162, 232], :c=>"y", :SV=>[{:name=>:sv, :width=>2, :length=>3, :height=>100}]})
    end
  end
end

# small
# http://0.0.0.0:3000/deck_width=5~deck_length=8~stdmax=500~EX_A1:B7=300_E1:E1=200~sv=2,3,100~sv2=4,5,100~rv_A,2,3,150_B,3,5,170_C,2,3,150_D,2,3,100~sort_order=L,W,1~placement=UL~a=vis=shc0,0,0,0~LL=3,0,162,232~c=y

# main test rv, sv
# http://0.0.0.0:3000/deck_width=20~deck_length=300~stdmax=500~EX_A1:B13=300_J1:J1=200~sv=2,3,100~rv_1,5,89,5_2,4,50,5_3,5,55,5_4,5,135,5_5,5,175,5_6,4,50,5_7,4,50,5_8,4,50,5_9,5,70,5~sort_order=W,L,1~placement=UL~a=vis=shc0,0,0,0~LL=3,0,162,232~c=n
# http://0.0.0.0:3000/deck_width=20~deck_length=200~stdmax=500~EX_A1:B13=300_J1:J1=200~sv=2,2,100~sv2=3,5,100~rv_V%251,5,89,5_V%252,5,50,5_V%253,5,55,5_V%254,5,135,5_V%255,5,175,5_V%256,5,50,5_V%257,5,50,5_V%258,5,50,5_V%259,5,70,5~sort_order=L,W,1~placement=UL~a=vis=shc0,0,0,0~LL=3,0,162,232~c=n
# http://0.0.0.0:3000/deck_width=20~deck_length=200~stdmax=500~EX_A1:B13=300_J1:J1=200~sv=2,2,100~sv2=3,5,100~rv_V1,5,89,5_V2,5,50,5_V3,5,55,5_V4,5,135,5_V5,5,175,5_V6,5,50,5_V7,5,50,5_V8,5,50,5_V9,5,70,5~sort_order=L,W,1~placement=UL~a=vis=shc0,0,0,0~LL=3,0,162,232~c=n

# long name
# http://0.0.0.0:3000/deck_width=20~deck_length=300~stdmax=500~EX_A1:B13=300_J1:J1=200~sv=2,3,100~rv_Vehicle%A,5,175,5_Vehicle%B,4,50,5_Vehicle%C,5,153,5_Vehicle%D,6,50,100_Vehicle%E,4,50,100_Vehicle%F,4,50,100~sort_order=L,W,1~placement=UL~a=vis=shc0,0,0,0~LL=3,0,162,232~c=n
# http://0.0.0.0:3000/deck_width=20~deck_length=300~stdmax=500~EX_A1:B13=300_J1:J1=200~sv=2,3,100~rv_Large%Vehicle%1,5,175,5_Large%Vehicle%2,5,153,5_Large%Vehicle%3,5,70,5_Large%Vehicle%4,5,60,5_Standard%Vehicle%1,4,50,5_Standard%Vehicle%2,4,50,5_Standard%Vehicle%3,4,50,5_Standard%Vehicle%4,4,50,5_Standard%Vehicle%5,4,50,5~sort_order=L,W,1~placement=UL~a=vis=shc0,0,0,0~LL=3,0,162,232~c=n

# problem with character
# http://0.0.0.0:3000/deck_width=20~deck_length=300~stdmax=500~EX_A1:B13=300_J1:J1=200~sv=2,3,100~rv_2K7QPN%25Hilux,5,55,5_2K9P6K%25Fuel%25Tanker%25,5,230,5_2KD4R4%25Pantec,5,76,5_2KGPPX%25Dyna,5,60,5_2KGQQ3%2553m%25Landcruiser%25+%256mTank%25Trailer,5,113,5~sort_order=L,W,1~placement=UL~a=vis=shc0,0,0,0~LL=3,0,162,232~c=n
# http://0.0.0.0:3000/deck_width=20~deck_length=250~stdmax=500~EX_A1:B13=300_J1:J1=200~sv=2,3,100~rv_2JM7ZQ%25Luggage%25Van,5,71,5_2JMM2Y%25Mail%25Trailer,5,70,5_2KFQZ7%25Landcrusier%25ute%25dual%25cab,5,57,5_2KFV7Z%25Navara,5,52,5_2KGDYP%25Campervan,5,72,5_2KH22C%25Carnival,4,50,5_2KH26P%25Condo%25Campervan,4,50,5_2KH3FK%25Toyota%25Land%25Cruiser%25wagon,4,50,5~sort_order=W,L,1~placement=UL~a=vis=shc0,0,0,0~LL=3,0,162,232~c=n
