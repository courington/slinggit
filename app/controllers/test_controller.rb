class TestController < ApplicationController
  #WORK IN PROGRESS DONT REMOVE
  def db_view
    table_html = ''
    table_names = ActiveRecord::Base.connection.tables.delete_if { |x| x == 'schema_migrations' }
    table_names.each do |name|
      table_name = "#{name.titleize.gsub(' ', '').singularize}"
      table_data = eval("#{table_name}.all")

      table_html << "<h2>#{table_name}</h2>"
      table_data.each do |row|
        table_html << "<ul>"
        row.attributes.each do |column_name, column_data|
          table_html << "<li>#{column_name} : #{column_data}</li>"
        end
        table_html << '</ul>'
      end

    end
    render :text => table_html
  end
end
