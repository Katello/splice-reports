module SpliceReports
  
  class FiltersController < ::ApplicationController

    before_filter :panel_options, :only => [:init_action, :index, :items]


    def rules
      read_system = lambda{System.find(params[:id]).readable?}
        {
          :index => lambda{true},
          :items => lambda{true},
          :new => lambda{true},
          :edit => lambda{true},
          :details => lambda{true},
          :update => lambda{true},
          :destroy => lambda{true}
        }

    end


    def index
      @filters = SpliceReports::Filter.all




      respond_to do |format|
        format.html
        format.json  { render :json => @filters}
      end
    end

    def panel_options
      @panel_options = {
          :title => _('Report Filters'),
          :col => ['name'],
          :titles => [_('Name')],
          :create => _('Report Filter'),
          :create_label => _('+ New Filter'),
          :name => controller_display_name,
          :ajax_load => true,
          :ajax_scroll=>items_splice_reports_filters_path(),
          :initial_action => :edit,
          :search_class => Filter,
          :enable_create => true
      }

    end

    def new
      @filter = Filter.new
      render :partial => "new", :locals => {:filter => @filter}
    end

    def controller_display_name
      return 'filter'
    end

    def edit
      @filter = Filter.find(params["id"])
      render :partial => "edit", :locals => {:editable => current_organization.editable?}

    end


    def update
      debugger
      updated_filter = Filter.find(params[:id])
      debugger
      result = params[:filter].values.first

      updated_filter.name = params[:filter][:name] unless params[:filter][:name].nil?

      unless params[:filter][:description].nil?
        result = updated_filter.description = params[:filter][:description].gsub("\n",'')
      end
      debugger
      updated_filter.save!
      notify.success _("Filter '%s' was updated.") % updated_filter.name

      if not search_validate(Filter, updated_filter.id, params[:search])
        notify.message _("'%s' no longer matches the current search criteria.") % updated_filter["name"]
      end

      render :text => escape_html(result)
    end

    def destroy
      #render and do the removal in one swoop!
      render :partial => "common/list_remove", :locals => {:id=>params[:id], :name=>controller_display_name}
    end


    def items
      render_panel_direct(Filter, @panel_options, params[:search], params[:offset], [:name_sort, 'asc'],
                          {:default_field => :name })
    end

  end 

end
