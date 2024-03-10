class CreateFinancialInfo < ActiveRecord::Migration[7.1]
  def change
    create_table :financial_infos do |t|
      t.text :data_source, null: false
      t.string :type_of_data, null: false
      t.string :flow_of_data, null: false
      t.text :compute_formulas, array: true, default: []
      t.references :user, null: false, foreign_key: true
      t.timestamps
    end
  end
end
