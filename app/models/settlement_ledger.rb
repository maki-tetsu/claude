# == Schema Information
#
# Table name: settlement_ledgers
#
#  id                  :integer          not null, primary key
#  ledger_number       :string(9)        not null
#  content             :string(40)       not null
#  note                :string(200)      not null
#  price               :integer          not null
#  application_date    :date             not null
#  applicant_user_id   :integer          not null
#  applicant_user_name :string(40)       not null
#  settlement_date     :date
#  settlement_note     :string(40)
#  completed_at        :datetime
#  deleted_at          :datetime
#  created_at          :datetime
#  updated_at          :datetime
#

class SettlementLedger < ActiveRecord::Base
  EXCEL_HEADER = %w[台帳No 内容 備考 精算金額 申請日 申請者 精算日 備考 精算完了 削除]
  CONTENT_VALUE = %w[営業経費精算書 通勤手当支給申請書 日帰or宿泊出張精算書 交通費精算書 その他]

  attr_accessor :completed

  belongs_to :applicant, foreign_key: 'applicant_user_id', class_name: 'User'

  validates :ledger_number, length: { is: 9 }, uniqueness: true
  validates :content, presence: true, length: { maximum: 40 }
  validates :note, presence: true, length: { maximum: 200 }
  validates :price, presence: true,  numericality: { only_integer: true, greater_than: 0, less_than: 1000000, allow_nil: true}
  validates :application_date, presence: true
  validates :applicant_user_id, presence: true
  validates :applicant_user_name, presence: true, length: { maximum: 40 }
  validates :settlement_note, length: { maximum: 40 }

  default_scope { order('ledger_number ASC') }

  scope :completed, -> { where('completed_at IS NOT NULL') }
  scope :not_completed, -> { where('completed_at IS NULL') }
  scope :deleted, -> { where('deleted_at IS NOT NULL') }
  scope :not_deleted, -> { where('deleted_at IS NULL') }

  before_validation :assign_ledger_number, on: :create

  def completed?
    completed_at.present?
  end

  def deleted?
    deleted_at.present?
  end

  def to_xlsx_value
    [
      ledger_number,
      content,
      note,
      price,
      application_date,
      applicant_user_name,
      settlement_date,
      settlement_note,
      completed? ? '○' : '×',
      deleted? ? '○' : '×'
    ]
  end

  # kobayashi
  # def put_ledger_number
  #   names.each do |name|
  #     random = [*1..10].sample  # 1から10のランダム値を取得
  #     Product.create! name: name, price: random * 1000, released_on: random.day.ago
  #   end
  # end

  def self.import(file)
    spreadsheet = open_spreadsheet(file)
    header = spreadsheet.row(1)

    (2..spreadsheet.last_row).each do |i|
      # {カラム名 => 値, ...} のハッシュを作成する
      row = Hash[[header, spreadsheet.row(i)].transpose]

      # IDが見つかれば、レコードを呼び出し、見つかれなければ、新しく作成
      product = find_by(id: row["id"]) || new
      # CSVからデータを取得し、設定する
      product.attributes = row.to_hash.slice(*updatable_attributes)
      # 保存する
      product.save!
    end
  end

  def self.open_spreadsheet(file)
    case File.extname(file.original_filename)
    when '.csv'  then Roo::Csv.new(file.path,    nil, :ignore)
    when '.xls'  then Roo::Excel.new(file.path,  nil, :ignore)
    when '.xlsx' then Roo::Excelx.new(file.path, nil, :ignore)
    when '.ods'  then Roo::OpenOffice.new(file.path, nil, :ignore)
    else raise "Unknown file type: #{file.original_filename}"
    end
  end

  private

  def assign_ledger_number
    latest = SettlementLedger.where('ledger_number LIKE ?', "#{Rails.configuration.ledger_number_prefix}%")
                             .order(:ledger_number).last
    if latest
      self.ledger_number = latest.ledger_number.succ
    else
      self.ledger_number = "#{Rails.configuration.ledger_number_prefix}001"
    end
  end
end
