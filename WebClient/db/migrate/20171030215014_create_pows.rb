class CreatePows < ActiveRecord::Migration[5.1]
  def change
    create_table :pow do |c|
      c.datetime :datetime
      c.integer  :power
      c.decimal  :factor
      c.integer  :voltage
      c.decimal  :current
      c.integer  :alarm_power
      c.boolean  :alarm_on
      c.integer  :period
    end
  end
end
