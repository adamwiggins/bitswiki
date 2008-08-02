module ActiveRecord
  module Acts #:nodoc:
    module Taggable #:nodoc:
      def self.included(base)
        base.extend(ClassMethods)   
      end
      
      module ClassMethods
        def acts_as_taggable(options = {})
          write_inheritable_attribute(:acts_as_taggable_options, {
            :taggable_type => ActiveRecord::Base.send(:class_name_of_active_record_descendant, self).to_s,
            :from => options[:from]
          })
          
          class_inheritable_reader :acts_as_taggable_options

          has_many :taggings, :as => :taggable, :dependent => :destroy
          has_many :tags, :through => :taggings

          include ActiveRecord::Acts::Taggable::InstanceMethods
          extend ActiveRecord::Acts::Taggable::SingletonMethods           
        end
      end
      
      module SingletonMethods
        def find_tagged_with(list)
          find_by_sql([
            "SELECT #{table_name}.* FROM #{table_name}, tags, taggings " +
            "WHERE #{table_name}.#{primary_key} = taggings.taggable_id " +
            "AND taggings.taggable_type = ? " +
            "AND taggings.tag_id = tags.id AND tags.name IN (?)",
            acts_as_taggable_options[:taggable_type], list
          ])
        end
      end
      
      module InstanceMethods
        def tag_with(list)
          Tag.transaction do
            taggings.destroy_all

            Tag.parse(list).each do |name|
              if acts_as_taggable_options[:from]
                tag = send(acts_as_taggable_options[:from]).tags.find_by_name(name) ||
                  send(acts_as_taggable_options[:from]).tags.create(:name => name)
              else
                tag = Tag.find_by_name(name) || Tag.create(:name => name)
              end
              tag.errors.each { |k, v| errors.add(k, v) }
              unless tag.errors.empty?
                raise RecordInvalid.new(tag)
              end
              tag.on(self)
            end
          end
        rescue RecordInvalid
        end

        def tag_list
          tags.collect { |tag| tag.name.include?(" ") ? "'#{tag.name}'" : tag.name }.join(" ")
        end
      end
    end
  end
end

=begin
Tag.parse(list).each do |name|
  if acts_as_taggable_options[:from]
    t = send(acts_as_taggable_options[:from]).tags.find_by_name(name) ||
      send(acts_as_taggable_options[:from]).tags.create!(:name => name)
    t.on(self)
  else
    t = Tag.find_by_name(name) || Tag.create!(:name => name)
    t.on(self)
  end
end
=end