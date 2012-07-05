module Push
  class FeedbackC2dm < Push::Feedback
    attr_accessible :device, :follow_up, :failed_at
    validates :follow_up, :inclusion => { :in => %w(delete), :message => "%{value} is not a valid follow-up" }
  end
end