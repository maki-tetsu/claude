#coding: utf-8

require '../spec_helper'

RSpec.describe SettlementLedgersController, :type => :controller do
let(:settlement_ledger) { FactoryGirl.create_list(:settlement_ledger, 5) }

  describe "GET index" do

    context "ログインしている場合" do
      # userをFactoryGirlで作る
      let(:admin) { FactoryGirl.create(:admin) }
      # 作ったユーザでログインする
      before do
        login_admin admin
        settlement_ledger
        get :index
      end
    
      # レスポンスが正しいこと
      it {expect(response).to be_success}
      # indexページを取得していること
      it {expect(response).to render_template(:index)}
    
      it "精算表の一覧が返されること" do
        expect(assigns[:settlement_ledgers]).not_to eq(nil)
        puts assigns[:settlement_ledgers].count
        assigns[:settlement_ledgers].each do |ledger|
          expect(ledger).to be_an_instance_of(SettlementLedger)
        end
      end
    end

    context "ログインしていない場合" do
      it "ログインページにリダイレクトされること" do
        get :index
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe "GET new" do

    context "ログインしている場合" do
      # userをFactoryGirlで作る
      let(:admin) { FactoryGirl.create(:admin) }
      # 作ったユーザでログインする
      before do
        login_admin admin
        get :new
      end

      # newページを取得していること
      it {expect(response).to render_template(:new)}
      it {expect(assigns[:settlement_ledger]).to be_an_instance_of(SettlementLedger)}
    end

    context "ログインしていない場合" do
      it "ログインページにリダイレクトされること" do
        get :new
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe "GET edit" do
    context "ログインしており" do
      # userをFactoryGirlで作る
      let(:admin) { FactoryGirl.create(:admin) }
      # 作ったユーザでログインする
      before do
        login_admin admin
      end
      
      context "有効な台帳が選択された場合" do
        before do
          @expected_settlement_ledger = FactoryGirl.create(:settlement_ledger, id: 1)
          get :edit, :id => @expected_settlement_ledger.id
        end

        it {expect(response).to render_template(:edit)}
        it {expect(assigns[:settlement_ledger].id).to eq(@expected_settlement_ledger.id)}
        end

      context "無効な台帳が選択された場合" do # URL直入力, 二重ログイン等
        it "データが存在しないエラー画面が表示されること" do
          expect{ SettlementLedger.find(-1) }.to raise_error ActiveRecord::RecordNotFound
         # get :edit, id: -1
         # expect(response).to render_template('settlement_ledgers/:id/edit')
        end
      end
    end

    context "ログインしていない場合" do
      it "ログインページにリダイレクトされること" do
        get :index
        expect(response).to redirect_to(new_user_session_path)
      end
    end

  end

  describe "POST create" do
    context "ログインしており" do
      let(:admin) { FactoryGirl.create(:admin) }
      before do
        login_admin admin
      end

      context "申請の登録に成功した場合" do
        it "申請が登録され、一覧ページにリダイレクトされること" do
          @settlement_ledger = FactoryGirl.create(:settlement_ledger, 
                                                 ledger_number: "AAA-99999",
                                                 content: "テスト",
                                                 note: "テスト",
                                                 price: 99999,
                                                 application_date: Date.today,
                                                 applicant_user_id: 1,
                                                 applicant_user_name: "申請者")
          
          allow(@settlement_ledger).to receive(:save).and_return(true)
          allow(SettlementLedger).to receive(:new).and_return(@settlement_ledger)
          post :create, settlement_ledger:{ ledger_number: "AAA-00001",
                                            content: "テスト",
                                            note: "テスト",
                                            price: 99999,
                                            application_date: Date.today,
                                            applicant_user_id: 1,
                                            applicant_user_name: "申請者" }
        
          expect(response).to redirect_to(settlement_ledgers_path)
          expect(flash[:notice]).to eq('精算依頼を登録しました。')
        end
      end

      context "申請の登録に失敗した場合" do
        it "新規作成ページが表示されること" do
          @settlement_ledger = build(SettlementLedger)
          p @settlement_ledger
          allow(@settlement_ledger).to receive(:save).and_return(false)
          allow(SettlementLedger).to receive(:new).and_return(@settlement_ledger)
          post :create, settlement_ledger: { ledger_number: "AAA-00001",
                                             content: "テスト",
                                             note: "テスト",
                                             price: 99999,
                                             application_date: Date.today,
                                             applicant_user_id: 1,
                                             applicant_user_name: "申請者" }
          expect(response).to render_template(:new)
        end
      end
    end

    context "ログインしていない場合" do
      it "ログインページにリダイレクトされること" do
        post :create
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe "PUT update" do
    context "ログインしており" do
      let(:admin) { FactoryGirl.create(:admin) }
      before do
        login_admin admin
      end

      context "存在しない申請を指定した場合" do
        it "RecordNotFoundエラーが発生すること" do
          expect { put :update, :id => -1 }.to raise_error(ActiveRecord::RecordNotFound)
        end
      end
      context "申請の更新に成功した場合" do
        it "申請が更新され、一覧ページにリダイレクトされること" do
          #params = { "id" => "1", "settlement_ledger" => { "content" => "test" } }
          @settlement_ledger = FactoryGirl.create(:settlement_ledger, 
                                                 ledger_number: "AAA-99999",
                                                 content: "テスト",
                                                 note: "テスト",
                                                 price: 99999,
                                                 application_date: Date.today,
                                                 applicant_user_id: 1,
                                                 applicant_user_name: "申請者")
          allow(SettlementLedger).to receive(:find).and_return(@settlement_ledger)
          
          put :update, id: 1, settlement_ledger:{ content: "test",
                                                  note: "test",
                                                  price: 99999}
          expect(response).to redirect_to(settlement_ledgers_path)
          expect(flash[:notice]).to eq('精算依頼を更新しました。')
        end
      end

      context "申請の更新に失敗した場合" do
        it "編集ページが表示されること" do
          @settlement_ledger = build(SettlementLedger)
          allow(@settlement_ledger).to receive(:update).and_return(false)
          allow(SettlementLedger).to receive(:find).and_return(@settlement_ledger)
          put :update, id: 1, settlement_ledger:{ content: "test",
                                                  note: "test",
                                                  price: 99999}
          expect(response).to render_template(:edit)
        end
      end
    end

    context "ログインしていない場合" do
      it "ログインページにリダイレクトされること" do
        get :index
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

end 
