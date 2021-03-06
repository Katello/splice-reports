#
# Copyright 2013 Red Hat, Inc.
#
# This software is licensed to you under the GNU General Public
# License as published by the Free Software Foundation; either version
# 2 of the License (GPLv2) or (at your option) any later version.
# There is NO WARRANTY for this software, express or implied,
# including the implied warranties of MERCHANTABILITY,
# NON-INFRINGEMENT, or FITNESS FOR A PARTICULAR PURPOSE. You should
# have received a copy of GPLv2 along with this software; if not, see
# http://www.gnu.org/licenses/old-licenses/gpl-2.0.txt.



module SpliceReports
  class Filter < ActiveRecord::Base
    include FilterSearch::Filter if Katello.config.use_elasticsearch

    has_and_belongs_to_many :organizations, :join_table => 'splice_reports_filters_organizations', :foreign_key=>'splice_reports_filter_id'
    belongs_to :user

    validates_with Validators::KatelloNameFormatValidator, :attributes => :name
    validates_with Validators::KatelloDescriptionFormatValidator, :attributes => :description

    validate :additional_criteria, :on => :create
    validate :sat_server_criteria, :on => :create
    validate :status_criteria, :on => :create
    validate :state_criteria, :on => :create
    validate :date_sanity, :on => :create
    validate :only_one_additional_criteria => :create

    def additional_criteria
      has_criteria = true
       if self.start_date.blank? && self.hours.blank? 
        has_criteria = false
        errors[:base] << "Please choose either a date range or number of hours"
        return has_criteria
      end
    end

    #Ensure only one of the additional criteria is set
    def only_one_additional_criteria
      custom_msg = ""
      error = false
      if !self.start_date.blank? &&  !self.hours.blank?
        custom_msg = "Start Date,  Number of Hours"
        error = true
      elsif !self.end_date.blank? &&  !self.hours.blank?
        custom_msg = "End Date, Number of Hours"
        error = true
      end
        
      if error
        errors[:base] << "Please choose only one of the options from Additional Filter
         Criteria: " << custom_msg + " were selected"
      end      
    end

    def date_sanity
      has_criteria = true
      if self.hours.blank?
        if self.start_date.blank? or self.end_date.blank?
          has_criteria = false
          errors[:base] << "Both the hour and date criteria of the filter are blank "
          return has_criteria
        elsif self.start_date > self.end_date 
          has_criteria = false
          errors[:base] << "The filter start date must be an earlier date than the filter end date."
          return has_criteria
        end
      end
    end

    def sat_server_criteria
      has_criteria = true
      if self.satellite_name.blank? 
        has_criteria = false
        errors[:base] << "A server name has not been defined in the database.  The backend splice tool must execute at least one time."
        return has_criteria
      end
    end

    def status_criteria
      has_criteria = true
      if self.status.blank? 
        has_criteria = false
        errors[:base] << "Please select at least one Subscription Status."
        return has_criteria
      end
    end

    def state_criteria
      has_criteria = true
      if self.state.blank? 
        has_criteria = false
        errors[:base] << "Please select at least one Lifecycle State."
        return has_criteria
      end
    end

    before_destroy :prevent_locked_deletion


    private 

    def prevent_locked_deletion
      if self.locked?
        Rails.logger.error _("Red Hat provided filters can not be deleted")
        false
      else
        true
      end
    end

  end 
end
