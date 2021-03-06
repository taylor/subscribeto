class DeliveryDetail < ActiveRecord::Base
  acts_as_archival :readonly_when_archived => true
  default_scope DeliveryDetail.unarchived
  
  attr_accessible :customer_id, :delivery_date_id, :invoice_id, :order_items_attributes
  
  has_many :order_items, :dependent => :destroy

  belongs_to :customer
  belongs_to :delivery_date
  belongs_to :invoice
  
  accepts_nested_attributes_for :order_items

end
