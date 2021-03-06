class DeliverySlot < ActiveRecord::Base
  acts_as_archival :readonly_when_archived => true
  default_scope DeliverySlot.unarchived
  
  attr_accessible :day, :start_time, :user_id
  
  belongs_to :user
  
  has_and_belongs_to_many :customers
  
  # has_many :delivery_dates, :dependent => :destroy
  has_many :bills
  has_many :order_items, through: :bills
  
  validates :day, :start_time, :user_id, presence: true
  validates_inclusion_of :day, in: ['Sunday', 'Monday', 'Tuesday','Wednesday','Thursday','Friday','Saturday']


  def get_date_for(week_start)
    case day
    when "Sunday"
      ret_date = week_start
    when "Monday"
      ret_date = week_start + 1.day
    when "Tuesday"
      ret_date = week_start + 2.days
    when "Wednesday"
      ret_date = week_start + 3.days
    when "Thursday"
      ret_date = week_start + 4.days
    when "Friday"
      ret_date = week_start + 5.days
    when "Saturday"
      ret_date = week_start + 6.days
    end
    
    return ret_date
  end

  def delivery_label
    day + start_time.strftime("%l:%M %p")
  end

  def self.delivery_schedule_for_day(day_of_week, id)
    DeliverySlot.where("day = ? AND user_id = ? ", day_of_week, id).includes(:undelivered_items) 
  end

  def customers_with_orders
    my_customers = []
    order_items.each do |order|
      if order.quantity and order.quantity > 0
        customer = order.bill.customer
        my_customers << customer unless my_customers.include? customer
      end
    end
    return my_customers
  end

  def items_by_customer(customer_id)
    my_items = {}
    bills = self.bills.find_by_customer_id(customer_id)
    bills.order_items.each do |order_item|
      if order_item.quantity and order_item.quantity > 0
        if !my_items[order_item.item.name].nil?
          my_items[order_item.item.name] += order_item.quantity
        else
          my_items[order_item.item.name] = order_item.quantity
        end
      end
    end
    return my_items
  end 

  def items
    my_items = {}
    order_items.each do |order_item|
      if order_item.quantity and order_item.quantity > 0
        if !my_items[order_item.item.name].nil?
          my_items[order_item.item.name] += order_item.quantity
        else
          my_items[order_item.item.name] = order_item.quantity
        end
      end
    end
    return my_items
  end

  def self.daily_summary(day_of_week, id)
    item_array = {}
    todays_slots = DeliverySlot.delivery_schedule_for_day(day_of_week, id)
    todays_slots.each do |slot|
      slot.items.each do |item|
        count = count_items(slot.id, item.id)
        if item_array[item.name].nil?
          item_array[item.name] = count if (count > 0)
        else
          total = item_array[item.name] + count
          item_array[item.name] = total
        end
      end
    end 
    return item_array
  end 
end
