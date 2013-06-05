class Order < ActiveRecord::Base
  attr_accessible :user_id, :customer_attributes, :item_id, :payment_due_attributes, :start_date,
    :customer_company, :line_items_attributes, :customer_id, :status, :total, :complete_date
  belongs_to :customer
  has_many :line_items, :dependent => :destroy
  has_many :items, :through => :line_items
  belongs_to :user
  has_one :payment_due
  accepts_nested_attributes_for :customer, :payment_due
  accepts_nested_attributes_for :line_items, :reject_if => :all_blank, :allow_destroy => true
  scope :new_orders, lambda { where("created_at > ?", Time.zone.now - 1.month ) }
  scope :delivered, where("status = ?", "Delivered").includes(:customer, { :line_items => :item })
  attr_accessor :customer_company
  validates :customer_id, :user_id, presence: true
  validates :line_items, :length => { :minimum => 1 }

  def self.update_status(order_id, status=nil)
    order = Order.includes(:line_items).find(order_id)
    if status.nil?
      count_check = order.line_items.count
      count = 0
      order.line_items.each do |line_item|
        count += 1 if line_item.delivered
      end
      if count == count_check
        order.status = "Delivered"
        order.complete_date = Date.today
      elsif (1..count_check).include?(count)
        order.status = "Partially Delivered"
      else
        order.status = "In Process"
      end
    else
      order.status = status
    end
    order.update_total
    order.save
  end

    
  def update_total
    self.total = 0
    line_items.each do |line_item|
      self.total += (line_item.price * line_item.qty_delivered)
      self.total -= (line_item.price * line_item.qty_returned)
    end
    self.save
  end

end
