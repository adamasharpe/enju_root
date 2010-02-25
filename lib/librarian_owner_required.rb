module LibrarianOwnerRequired
  def self.included(base)
    base.extend AclClassMethods
    base.instance_eval do
      include InstanceMethods
    end
  end

  module AclClassMethods
    def is_indexable_by(user, parent = nil)
      true
    end

    def is_creatable_by(user, parent = nil)
      user.has_role?('User')
    rescue
      false
    end
  end

  module InstanceMethods
    include RoleRequired

    def is_readable_by(user, parent = nil)
      if user
        return true if user == self.user || user.has_role?('Librarian')
      end
      return true if self.role_accepted?(user)
    rescue
      false
    end

    def is_updatable_by(user, parent = nil)
      if user
        return true if user == self.user || user.has_role?('Librarian')
      end
    rescue
      false
    end

    def is_deletable_by(user, parent = nil)
      return true if user == self.user || user.has_role?('Librarian')
    rescue
      false
    end
  end
end
