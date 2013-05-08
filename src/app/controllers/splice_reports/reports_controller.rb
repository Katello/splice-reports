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
  
  class ReportsController < ::ApplicationController

    before_filter :find_record, :only=>[:record, :facts]

    def rules
      read_system = lambda{System.find(params[:id]).readable?}
        {
          :show => lambda{true},
          :items => lambda{true},
          :record => lambda{true},
          :facts=> lambda{true}
        }

    end

    def show
      @filter = SpliceReports::Filter.find(params[:id])


      #render :partial => "reports/report"
      #render :partial => "report", :locals => {:report_invalid => @report_invalid, :report_valid => @report_valid}
      render 'show'
    end


    def items
      #find the selected filter
      @filter = SpliceReports::Filter.where(:id=>params[:id]).first
      # connect to mongo collection
      c = SpliceReports::MongoConn.new.get_coll_marketing_report_data()

      #add report criteria
      @report_row = c.find({"status" => @filter[:status]}).as_json
      #debug
      #render :json=>{ :subtotal => 1, :total=>1, :systems=> [c.find_one]  }
      render :json=>{ :subtotal => 1, :total=>1, :systems=> @report_row  }
    end


    def record

      render :partial=>'record'

    end

    def facts
      @record['facts'] = @record['facts'].collect do |f|
        f[0] = f[0].gsub('_dot_', '.')
        #manualyl adjust systemid to not mess up the rendering
        f[0] = 'system.id' if f[0] == 'systemid'
        f
      end

      render :partial=>'facts'
    end


    def find_record
      record_id = params[:id]
      c = SpliceReports::MongoConn.new.get_coll_marketing_report_data()
      @record = c.find({"record_identifier" => record_id}).first
    end

  end 

end
