require 'spec_helper'

describe SeeAsVee do
  it 'has a version number' do
    expect(SeeAsVee::VERSION).not_to be nil
  end

  it 'throws an exception on invalid input' do
    expect { SeeAsVee::Helpers.file_with_type(5) }.to raise_error(SeeAsVee::Exceptions::BadInputError)
  end

  it 'loads csv properly' do
    # rubocop:disable Style/NumericLiterals
    expect([
      'spec/fixtures/velocity.xlsx',
      'spec/fixtures/velocity.csv',
      "a,b,c\n1,2,3"
    ].map do |f|
      SeeAsVee::Helpers.harvest_csv(f)
    end.uniq).to match_array(
      [
        [%w(a b c), %w(1 2 3)],
        [
          [
            "Reference", "Parent", "User", "Trade Date", "Status", "Legal Entity",
            "Counterpart", "Product", "Action", "Currency 1", "Currency 2",
            "Notional", "Notional Currency", "Effective Period", "Effective Date",
            "Maturity Period", "Maturity Date", "Limit / Strike", "Quote", "Order",
            "Type", "Fiduciary", "Expiry", "Spot Rate", "Near Points", "Near Forward Rate",
            "Far Points", "Far Forward Rate", "USI/UTI", "Far Leg USI/UTI", "Kantox", "Counter Value"
          ],
          [
            243723114.0, nil, "KANTOX.Anton", "04.03.2016 10:30:45.391", "EXEC", "Kantox",
            "VELOCITY TRADE", "Forward", "Buy", "GBP", "EUR", 4557210.31, "GBP",
            "TOMORROW", "07-Mar-16", "TOMORROW", "07-Mar-16", nil, 1.289802, "NO",
            "Standard Request For Quote", "NO", "04/03/2016 10:31", 1.28977, 0.32,
            1.289802, nil, nil, 1.01e+18, nil, "O-Y7CFVBWAB", 5881079.91
          ]
        ],
        [
          [
            "Reference", " Parent", "User", "Trade  Date", "Status", "Legal Entity",
            "Counterpart ", "Product", "Action", "Currency 1", "Currency 2",
            "Notional", "Notional Currency", "Effective Period", "Effective Date",
            "Maturity Period", "Maturity Date", "Limit / Strike", "Quote", "Order",
            "Type", "Fiduciary", "Expiry", "Spot Rate", "Near Points", "Near Forward Rate",
            "Far Points", "Far Forward Rate", "USI/UTI", "Far Leg USI/UTI", "Kantox", "Counter Value"
          ],
          [
            "243723114", nil, "KANTOX.Алексей", "04.03.2016 10:30:45.391", "EXEC", "Kantox",
            "VELOCITY TRADE", "Forward", "Buy", "GBP", "EUR", "4557210.31", "GBP",
            "TOMORROW", "07-Mar-16", "TOMORROW", "07-Mar-16", nil, "1.289802", "NO",
            "Standard Request For Quote", "NO", "04/03/2016 10:31", "1.28977", "0.32",
            "1.289802", nil, nil, "1.01E+018", nil, "O-Y7CFVBWAB", "5881079.91"
          ],
          [
            "243723113", nil, "KANTOX.Алексей", "04.05.2016 10:30:45.391", "EXEC", "Kantox",
            "VELOCITY TRADE", "Forward", "Sell", "EUR", "GBP", "455447210.31", "GBP",
            "TOMORROW", "07-Mar-16", "TOMORROW", "07-Mar-16", nil, "1.289802", "NO",
            "Standard Request For Quote", "NO", "04/03/2016 10:31", "1.28977", "0.32",
            "1.289802", nil, nil, "1.01E+018", nil, "O-Y7CFVBWAB", "5881049.91"
          ]
        ]
      ]
    )
    # rubocop:enable Style/NumericLiterals
  end

  it 'skips blank rows with option' do
    # rubocop:disable Style/NumericLiterals
    SeeAsVee.harvest(
      'spec/fixtures/velocity_with_blank_lines.csv', skip_blank_rows: true
    ) do |idx, errors, hash|
      expect(hash.to_a.transpose).to eq(
        [
          [
            "Reference", " Parent", "User", "Trade  Date", "Status", "Legal Entity",
            "Counterpart ", "Product", "Action", "Currency 1", "Currency 2",
            "Notional", "Notional Currency", "Effective Period", "Effective Date",
            "Maturity Period", "Maturity Date", "Limit / Strike", "Quote", "Order",
            "Type", "Fiduciary", "Expiry", "Spot Rate", "Near Points", "Near Forward Rate",
            "Far Points", "Far Forward Rate", "USI/UTI", "Far Leg USI/UTI", "Kantox", "Counter Value"
          ],
          [
            "243723114", nil, "KANTOX.Алексей", "04.03.2016 10:30:45.391", "EXEC", "Kantox",
            "VELOCITY TRADE", "Forward", "Buy", "GBP", "EUR", "4557210.31", "GBP",
            "TOMORROW", "07-Mar-16", "TOMORROW", "07-Mar-16", nil, "1.289802", "NO",
            "Standard Request For Quote", "NO", "04/03/2016 10:31", "1.28977", "0.32",
            "1.289802", nil, nil, "1.01E+018", nil, "O-Y7CFVBWAB", "5881079.91"
          ]
        ]
      )
    end
    # rubocop:enable Style/NumericLiterals
  end

  it "loads csv into sheet properly" do
    sheet = SeeAsVee::Sheet.new 'spec/fixtures/velocity.xlsx', formatters: { reference: ->(v) { v.round.to_s } }
    sheet.each do |idx, errors, hash|
      expect(idx).to be_zero
      expect(errors).to be_empty
      expect(hash["Reference"]).to eq "243723114"
      expect(hash["Kantox"]).to eq "O-Y7CFVBWAB"
    end
  end

  it "places “danger” sign when checkers do not pass" do
    sheet = SeeAsVee::Sheet.new 'spec/fixtures/velocity.xlsx', checkers: { reference: ->(v) { v == v.round.to_s } }
    sheet.each do |idx, errors, hash|
      expect(idx).to be_zero
      expect(errors).not_to be_empty
      expect(errors["Reference"]).to eq "#{SeeAsVee::Sheet::CELL_ERROR_MARKER}2̶4̶3̶7̶2̶3̶1̶1̶4̶.̶0̶"
      expect(hash["Reference"]).to eq "#{SeeAsVee::Sheet::CELL_ERROR_MARKER}2̶4̶3̶7̶2̶3̶1̶1̶4̶.̶0̶"
      expect(hash["Kantox"]).to eq "O-Y7CFVBWAB"
    end
  end

  it "applies checkers after formatters and produces files" do
    sheet = SeeAsVee.harvest('spec/fixtures/velocity.xlsx',
                              formatters: { reference: ->(v) { v.round.to_s } },
                              checkers: { reference: ->(v) { v.nil? } }) do |idx, errors, hash|
      expect(idx).to be_zero
      expect(errors["Reference"]).to eq "#{SeeAsVee::Sheet::CELL_ERROR_MARKER}2̶4̶3̶7̶2̶3̶1̶1̶4̶"
      expect(hash["Reference"]).to eq "#{SeeAsVee::Sheet::CELL_ERROR_MARKER}2̶4̶3̶7̶2̶3̶1̶1̶4̶"
      expect(hash["Kantox"]).to eq "O-Y7CFVBWAB"
    end
    # rubocop:disable Style/ZeroLengthPredicate
    csv, xlsx = sheet.produce csv: true, xlsx: true
    expect(File.exist?(csv.path)).to eq true
    expect(csv.length > 0).to eq true
    expect(File.exist?(xlsx.path)).to eq true
    expect(xlsx.length > 0).to eq true
    # rubocop:enable Style/ZeroLengthPredicate
  end

  it "applies schema as checker" do
    m = %w[Params Form].detect(&Dry::Validation.method(:respond_to?))
    schema = Dry::Validation.public_send(m) do
      required(:reference) { filled? > str? }
      required(:parent).value(:empty?)
      required(:user).filled(:str?)
      required(:trade_date).filled(:date?)
      required(:status).filled(:str?)
      required(:legal_entity).filled(:str?)
      required(:counterpart).filled(:str?)
      required(:product).filled(:str?)
      required(:action).filled(:str?)
      required(:currency_1).filled(:str?)
      required(:currency_2).filled(:str?)
      required(:notional).filled(:float?)
      required(:notional_currency).filled(:str?)
      required(:effective_period).filled(:str?)
      required(:effective_date).filled(:date?)
      required(:maturity_period).filled(:str?)
      required(:maturity_date).filled(:date?)
      required(:spot_rate).filled(:float?)
      required(:near_forward_rate).filled(:float?)
    end
    validation = SeeAsVee.validate('spec/fixtures/velocity.csv', schema)
    expect(validation.all? { |vr| vr.errors.empty? }).to be true
  end

  it 'throws an exception on unknown file format' do
    expect { SeeAsVee::Helpers.file_with_type('spec/fixtures/velocity.xls') }.to \
      raise_error(SeeAsVee::Exceptions::FileFormatError)
  end
end
