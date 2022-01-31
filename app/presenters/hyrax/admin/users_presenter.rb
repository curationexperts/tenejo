# frozen_string_literal: true
module Hyrax
  module Admin
    class UsersPresenter
      # @return [Array] an array of Users & and array of roles
      def users
        @users ||= search
      end

      def roles
        @roles ||= Role.all
      end

      # @return [Number] quantity of users excluding the system users and guest_users
      def user_count
        users.count
      end

      # @return [Array] an array of user roles
      def user_roles(user)
        user.groups
      end

      def last_accessed(user)
        user.last_sign_in_at || user.created_at
      end

      # return [Boolean] true if the devise trackable module is enabled.
      def show_last_access?
        return @show_last_access unless @show_last_access.nil?
        @show_last_access = ::User.devise_modules.include?(:trackable)
      end

      private

      # Returns a list of users excluding the system users and guest_users, eagerly load roles
      def search
        ::User.includes(:roles).registered.without_system_accounts
      end
    end
  end
end
