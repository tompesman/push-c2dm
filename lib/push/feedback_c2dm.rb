module Push
  class FeedbackC2dm < Push::Feedback
    attr_accessible :app, :device, :follow_up, :failed_at if defined?(ActiveModel::MassAssignmentSecurity)
    validates :follow_up, :inclusion => { :in => %w(delete), :message => "%{value} is not a valid follow-up" }
  end
end