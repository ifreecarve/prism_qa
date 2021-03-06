require 'markaby'
require_relative 'filesystem'

module PrismQA

  # A Prism report is an object whose to_s method returns HTML for the full report.
  class Report

    attr_accessor :title
    attr_accessor :attribute
    attr_accessor :design_spectrum
    attr_accessor :app_spectra
    attr_accessor :web_document_root
    attr_accessor :destination_path
    attr_accessor :img_width_px

    def css
      width_string = ''
      width_string = "width: #{@img_width_px}px;" unless img_width_px.nil?
      %(
        body {color:white; background-color:#333;}
        table.comparison th {border-top: 1px solid #ccc;}
        table.comparison td {padding-bottom:1ex; text-align:center;}
        .masterimg, .appimg {background-color:white; #{width_string}}
        .img {border:0;}
        .missing {text-align:center; #{width_string}}
       )
    end

    # if necessary, modify the path to be relative (for web-based reports)
    def path_transform(element_path)
      unless @web_document_root.nil?
        element_path = web_relative_path(@web_document_root, @destination_path, element_path)
      end
      element_path
    end

    def candidates_for_attribute
      @app_spectra.select do |app_spectrum|
        next true if @attribute.nil? # unless there is nothing in this candidate???? might be expensive to check.
        app_spectrum.image_set.target.attribute == @attribute
      end
    end

    # make a list of problems found
    def test_input
      problems = []
      @app_spectra.each do |app_spectrum|
        problems << 'App spectrum has a nil target defined in its image set' if app_spectrum.image_set.target.nil?
      end
      problems
    end

    # raise an error if any problems are found
    def validate_input
      problems = test_input
      raise OperationalError, "Found the following problems: #{problems}" unless problems.empty?
    end

    # render the report
    def to_s
      validate_input

      # initial calculations - get the app spectra that support the attribute we are reporting on
      candidates = candidates_for_attribute
      design_images = @design_spectrum.image_set.images_for_attribute(@attribute)
      columns = candidates.length + 1

      me = self

      # build html
      mab = Markaby::Builder.new
      mab.html do

        head do
          title "#{me.title} | Prism QA"
          style type: 'text/css' do
            me.css
          end
        end

        body do
          h1 me.title
          if design_images.empty?
            p 'No input images were found.'
          else
            table.comparison do
              # print out the first row of the table -- the target names
              tr do
                td 'Design'
                candidates.each do |c|
                  td c.image_set.target.name
                end
              end

              # print out all the compared images
              design_images.each do |design_image|
                # title
                tr do
                  th colspan: columns do
                    a name: design_image.description do
                      design_image.description
                    end
                  end
                end

                # images
                tr do
                  td align: 'right', valign: 'top' do
                    src = me.path_transform(design_image.path)
                    a href: src do
                      img.masterimg src: src, alt: design_image.description
                    end
                  end

                  candidates.each do |candidate|
                    app_image = candidate.image_set.best_image_for(design_image.id)
                    if app_image.nil?
                      td { div.missing "#{design_image.description} on #{candidate.image_set.target.name}" }
                    else
                      td align: 'left', valign: 'top' do
                        div.holder do
                          src = me.path_transform(app_image.path)
                          a href: src do
                            img.appimg src: src, alt: app_image.description
                          end
                        end
                      end
                    end
                  end
                end
              end
            end
          end
        end
      end
      mab.to_s
    end

  end

end
