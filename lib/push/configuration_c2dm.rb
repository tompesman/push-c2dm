module Push
  class ConfigurationC2dm < Push::Configuration
    store :properties, accessors: [:email, :password]
    attr_accessible :app, :enabled, :connections, :email, :password if defined?(ActiveModel::MassAssignmentSecurity)
    validates :email, :presence => true
    validates :password, :presence => true

    def name
      :c2dm
    end
  end
end