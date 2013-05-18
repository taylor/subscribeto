class DeliverySlot < ActiveRecord::Base
  attr_accessible :day, :start_time, :user_id
  belongs_to :user
  has_many :line_items
  has_many :items, through: :undelivered_items
  has_many :orders, through: :undelivered_items
  has_many :undelivered_items, :class_name => 'LineItem', :conditions => ['delivered = ?', false]


  def delivery_label
    day + start_time.strftime(" %l:%M %p")
  end

  def self.delivery_schedule_for_day(day_of_week, id)
    DeliverySlot.where("day = ? AND user_id = ? ", day_of_week, id).includes(:undelivered_items) 
  end

  def self.count_items(slot_id, item_id)
    count = 0
    slot = DeliverySlot.find(slot_id)
    slot.line_items.each do |line_item|
      if line_item.item_id == item_id
        count += line_item.quantity unless line_item.delivered
      end
    end 
    return count
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