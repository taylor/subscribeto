class Invoice < ActiveRecord::Base
  acts_as_archival :readonly_when_archived => true
  default_scope Invoice.unarchived.includes(:customer, :order_items)
  
  attr_accessible :customer_id, :user_id, :weekly_schedule_id, :memo, :invoice_number, :due_date, :amount_due, :order_items_attributes, :complete_due_date, :amount_due
  
  belongs_to :customer
  belongs_to :user
  belongs_to :weekly_schedule
  has_one :bill
  
  # has_many :delivery_details
  has_many :order_items
  
  after_initialize :default_values
  
  validates_uniqueness_of :invoice_number, scope: :user_id

  accepts_nested_attributes_for :order_items, :allow_destroy => true

  attr_accessor :amount_due

  def complete_due_date
    due_date.strftime("%m/%d/%Y") if due_date
  end

  def complete_due_date=(value)
    self.due_date = Date.strptime(value, '%m/%d/%Y') if value
  end

  def default_values
    if new_record?
      self.memo = "Thank you for your business!" if self.memo.nil?
      self.due_date = self.due_date_with_terms if self.due_date.nil?
      self.save
    end
  end

  def invoice_date_iif
    created_at.strftime("%m/%d/%y")
  end

  # def order_items
  #   delivery_details.flat_map{|n| n.order_items }.find_all{|n| n.quantity>0}
  # end

  def amount_due
    total = 0
    order_items.each do |order_item|  
      total += order_item.subtotal
    end
    return total
  end

  def amount_due_iif
    0 - amount_due
  end

  def formatted_due_date

    the_due_date = created_at
    if customer.term == "Due upon receipt"
      return customer.term
    else
      case customer.term
      when "Net 30"
        the_due_date += 30.day
      when "Net 7"
        the_due_date += 7.day
      when "Net 10"
        the_due_date += 10.day
      when "Net 15"
        the_due_date += 15.day
      when "Net 60"
        the_due_date += 60.day
      end
    end
    return the_due_date.strftime("%B %d, %Y")
  end

  def due_date_with_terms

    the_due_date = Time.now
    if customer.term == "Due upon receipt"
      the_due_date = self.bill.scheduled_for 
    else
      case customer.term
      when "Net 30"
        the_due_date += 30.day
      when "Net 7"
        the_due_date += 7.day
      when "Net 10"
        the_due_date += 10.day
      when "Net 15"
        the_due_date += 15.day
      when "Net 60"
        the_due_date += 60.day
      end
    end
    the_due_date
  end
  
end
