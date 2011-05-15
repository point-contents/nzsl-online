class Feedback < ActiveRecord::Base
  validates_presence_of :name
  validates_presence_of :message
  
  validates_format_of :email, :with => /^([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})$/i, :allow_nil => true
  
  has_attached_file :video,
    :url => "/no-video",
    :path => ":rails_root/data/uploaded/feedback/:id/:basename.:extension"
  
  validates_attachment_size :video, :less_than => 5.megabytes, :allow_nil => true

  
  def send_email
    begin
      FeedbackMailer.email(self).deliver
      self.video = nil
      self.save
    rescue
      return false
    end
  end
end