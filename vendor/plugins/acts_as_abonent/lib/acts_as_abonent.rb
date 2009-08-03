module Killich #:nodoc:
  module Acts #:nodoc:
    module Abonent #:nodoc:
      def self.included(base)
        base.extend(SingletonMethods)
      end
      
      module SingletonMethods
        def acts_as_abonent
          include AbonentMethods
        end# acts_as_abonent
      end# SingletonMethods
      
      module AbonentMethods
        # Ролевая политика (Наиболее общая)
        def role_policies_hash
          @role_policies_hash ||= (self.role ? (self.role.settings.is_a?(String) ? YAML::load(self.role.settings) : Hash.new) : Hash.new )
        end
        
        # interfaces
        def has_role_policy?(section, action)
          return false unless role_policies_hash[section.to_sym] && role_policies_hash[section.to_sym][action.to_sym]
          role_policies_hash[section.to_sym][action.to_sym]
        end
        
        def is_owner_of?(obj)
          return false unless obj
          return false unless (obj.class.superclass == ActiveRecord::Base)
          return self.id == obj.id          if obj.is_a?(User)
          return self.id == obj[:user_id]   if obj[:user_id]
          return self.id == obj[:user][:id] if obj[:user]
          false
        end

        # Базовые функции проверки актаульности
        def policy_actual_by_counter?(counter, max_count)
          return true unless max_count && counter
          counter <= max_count
        end

        def policy_actual_by_time?(start_at, finish_at)
          return true if (!start_at && !finish_at)
          now= DateTime.now
          return (finish_at.to_datetime >= now) unless start_at
          return (start_at.to_datetime  <= now) unless finish_at
          start_at.to_datetime <= now && now <= finish_at.to_datetime
        end

        # Базовые функции работы со счетчиком
        def counter_should_be_updated?(policy_hash)
          return false unless policy_hash.is_a?(Hash)
          return false unless policy_hash[:counter] && policy_hash[:max_count]
          policy_hash[:counter] <= policy_hash[:max_count]
        end
        
        def update_policy_counter(options = {}) 
          opts = {
            :update_table=>false,
            :updated_policy=>false,
            :counter_increment=>1
          }.merge!(options)
          return if opts[:counter_increment].nil? || opts[:counter_increment] == 0
          return if !opts[:update_table] || !opts[:updated_policy]
          return unless opts[:updated_policy].is_a?(Hash)
          return unless opts[:updated_policy][:id]
          eval("#{opts[:update_table]}.update_counters(#{opts[:updated_policy][:id]}, :counter=>#{opts[:counter_increment]})")
          opts[:updated_policy][:counter]= opts[:updated_policy][:counter]+opts[:counter_increment]
        end
        
        # Базовые функции проверки доступа/блокировки
        def create_policy_hash(options = {})
          opts = {
            :hash_name =>   false,
            :before_find => false,
            :finder =>      false, 
            :recalculate => false
          }.merge!(options)
          eval("@#{opts[:hash_name]} = nil  if opts[:recalculate]")
          eval("return if @#{opts[:hash_name]}")
          result_hash= Hash.new
          eval("@#{opts[:hash_name]} = result_hash")
          return unless (opts[:finder] || opts[:hash_name])
          eval(opts[:before_find]) if opts[:before_find]
          eval(opts[:finder]).each do |policy|
            _action_hash={
              policy.action.to_sym=>{
                :id=>policy.id,
                :value=>policy.value,
                :start_at=>policy.start_at,
                :finish_at=>policy.finish_at,
                :counter=>policy.counter,
                :max_count=>policy.max_count
              }
            }
            if result_hash.has_key?(policy.section.to_sym)
              result_hash[policy.section.to_sym].merge!(_action_hash)
            else
              _hash={ policy.section.to_sym => _action_hash }        
              result_hash.merge!(_hash)                              
            end
          end
          eval("@#{opts[:hash_name]}= result_hash")
          return
        end
        
        def check_policy(section, action, hash_name, options = {})
          opts = {
            :recalculate => false,
            :return_invert=>false,
            :policy_table=>false
          }.merge!(options)
          send("create_#{hash_name}", opts)
          return false if !eval("@#{hash_name}").values_at(section.to_sym) || !eval("@#{hash_name}").values_at(section.to_sym).first
          section_of_policies_hash= eval("@#{hash_name}").values_at(section.to_sym).first
          return false if !section_of_policies_hash.values_at(action.to_sym) || !section_of_policies_hash.values_at(action.to_sym).first
          policy_hash= section_of_policies_hash.values_at(action.to_sym).first
          value= opts[:return_invert] ? !policy_hash[:value] : policy_hash[:value]
          time_check=     policy_actual_by_time?(policy_hash[:start_at], policy_hash[:finish_at])
          counter_check=  policy_actual_by_counter?(policy_hash[:counter], policy_hash[:max_count])
          update_opts={ :update_table=>opts[:update_table], :updated_policy=>policy_hash}
          update_opts[:counter_increment]= opts[:counter_increment] if opts[:counter_increment]
          update_policy_counter(update_opts) if counter_should_be_updated?(policy_hash) && time_check
          return value if counter_check && time_check
          false
        end
        
        def policy_exists(section, action, hash_name, options = {})
          opts = {
            :recalculate => false
          }.merge!(options)
          send("create_#{hash_name}", opts)
          return false if !eval("@#{hash_name}").values_at(section.to_sym) || !eval("@#{hash_name}").values_at(section.to_sym).first
          section_of_policies_hash= eval("@#{hash_name}").values_at(section.to_sym).first
          return false if !section_of_policies_hash.values_at(action.to_sym) || !section_of_policies_hash.values_at(action.to_sym).first
          true
        end

        def get_policy_hash(section, action, hash_name, options = {})
          opts = {
            :recalculate => false,
          }.merge!(options)
          send("create_#{hash_name}", opts)
          return nil if !eval("@#{hash_name}").values_at(section.to_sym) || !eval("@#{hash_name}").values_at(section.to_sym).first
          section_of_policies_hash= eval("@#{hash_name}").values_at(section.to_sym).first
          return nil if !section_of_policies_hash.values_at(action.to_sym) || !section_of_policies_hash.values_at(action.to_sym).first
          section_of_policies_hash.values_at(action.to_sym).first
        end
        
        # Персональная политика
        def create_personal_policies_hash(options = {})
          opts= {
            :hash_name=>'personal_policies_hash',
            :finder=>'PersonalPolicy.find_all_by_user_id(self.id)'
          }
          create_policy_hash options.merge!(opts)
          @personal_policies_hash
        end
        
        # interfaces
        def personal_policy_exists?(section, action, options = {})
          policy_exists(section, action, 'personal_policies_hash', options)
        end
        
        def get_personal_policy(section, action, options = {})
          get_policy_hash(section, action, 'personal_policies_hash', options)
        end
        
        def has_personal_access?(section, action, options = {})
          opts={ :update_table=>'PersonalPolicy' }
          check_policy(section, action, 'personal_policies_hash', options.merge!(opts))
        end

        def has_personal_block?(section, action, options = {})
          opts={ :update_table=>'PersonalPolicy', :return_invert=>true }
          check_policy(section, action, 'personal_policies_hash', options.merge!(opts))
        end

        # Групповая политика
        def create_group_policies_hash(options = {})
          opts= {
            :hash_name=>'group_policies_hash',
            :before_find=>'return unless self.role',
            :finder=>'GroupPolicy.find_all_by_role_id(self.role.id)'
          }
          create_policy_hash options.merge!(opts)
          @group_policies_hash
        end
        
        # interfaces
        def group_policy_exists?(section, action, options = {})
          policy_exists(section, action, 'group_policies_hash', options)
        end
        
        def get_group_policy(section, action, options = {})
          get_policy_hash(section, action, 'group_policies_hash', options)
        end
        
        def has_group_access?(section, action, options = {})
          opts={ :update_table=>'GroupPolicy' }
          check_policy(section, action, 'group_policies_hash', options.merge!(opts))
        end

        def has_group_block?(section, action, options = {})
          opts={ :update_table=>'GroupPolicy', :return_invert=>true }
          check_policy(section, action, 'group_policies_hash', options.merge!(opts))
        end

        # Общие функции ресурсной политики
        def create_resources_policies_hash_for_class_of(resource, options = {})
          opts = {
            :hash_name =>   false,
            :before_find => false,
            :finder =>      false
          }.merge!(options)
          resource_class=  resource.class.to_s
          result_hash= Hash.new
          eval("@#{opts[:hash_name]}= nil") if (eval("@#{opts[:hash_name]}") && opts[:reset])
          eval("@#{opts[:hash_name]}")[resource_class.to_sym]= nil if (eval("@#{opts[:hash_name]}") && eval("@#{opts[:hash_name]}")[resource_class.to_sym] && opts[:recalculate])
          eval("@#{opts[:hash_name]}= Hash.new") unless eval("@#{opts[:hash_name]}")
          return if eval("@#{opts[:hash_name]}")[resource_class.to_sym]
          return unless (opts[:finder] || opts[:hash_name])
          eval(opts[:before_find]) if opts[:before_find]    
          eval(opts[:finder]).each do |policy|
              result_hash[policy.resource_id]= {
                policy.section.to_sym=>{
                  policy.action.to_sym=>{
                    :id=>policy.id,
                    :value=>policy.value,
                    :start_at=>policy.start_at,
                    :finish_at=>policy.finish_at,
                    :counter=>policy.counter,
                    :max_count=>policy.max_count
                  }
                } 
              }
          end
          eval("@#{opts[:hash_name]}")[resource_class.to_sym]= result_hash
          return
        end
        
        def check_resource_policy(object, section, action, hash_name, options = {})
          opts = {
            :recalculate => false,
            :reset => false,
            :return_invert=>false
          }.merge!(options)
          send("#{hash_name}_for_class_of", object, opts)
          return false if     eval("@#{hash_name}")[object.class.to_s.to_sym].empty?
          return false unless eval("@#{hash_name}")[object.class.to_s.to_sym][object.id]
          return false unless eval("@#{hash_name}")[object.class.to_s.to_sym][object.id][section.to_sym]
          return false unless eval("@#{hash_name}")[object.class.to_s.to_sym][object.id][section.to_sym][action.to_sym]
          policy_hash= eval("@#{hash_name}")[object.class.to_s.to_sym][object.id][section.to_sym][action.to_sym]
          value= opts[:return_invert] ? !policy_hash[:value] : policy_hash[:value]
          time_check=     policy_actual_by_time?(policy_hash[:start_at], policy_hash[:finish_at])
          counter_check=  policy_actual_by_counter?(policy_hash[:counter], policy_hash[:max_count])
          update_opts={ :update_table=>opts[:update_table], :updated_policy=>policy_hash}
          update_opts[:counter_increment]= opts[:counter_increment] if opts[:counter_increment]
          update_policy_counter(update_opts) if counter_should_be_updated?(policy_hash) && time_check
          return value if counter_check && time_check
          false
        end

        def resource_policy_exists(object, section, action, hash_name, options = {})
          opts = {
            :recalculate => false,
            :reset => false
          }.merge!(options)
          send("#{hash_name}_for_class_of", object, opts)
          return false if     eval("@#{hash_name}")[object.class.to_s.to_sym].empty?
          return false unless eval("@#{hash_name}")[object.class.to_s.to_sym][object.id]
          return false unless eval("@#{hash_name}")[object.class.to_s.to_sym][object.id][section.to_sym]
          return false unless eval("@#{hash_name}")[object.class.to_s.to_sym][object.id][section.to_sym][action.to_sym]
          true
        end

        def get_resource_policy_hash(object, section, action, hash_name, options = {})
          opts = {
            :recalculate => false,
            :reset => false
          }.merge!(options)
          send("#{hash_name}_for_class_of", object, opts)
          return nil if     eval("@#{hash_name}")[object.class.to_s.to_sym].empty?
          return nil unless eval("@#{hash_name}")[object.class.to_s.to_sym][object.id]
          return nil unless eval("@#{hash_name}")[object.class.to_s.to_sym][object.id][section.to_sym]
          return nil unless eval("@#{hash_name}")[object.class.to_s.to_sym][object.id][section.to_sym][action.to_sym]
          eval("@#{hash_name}")[object.class.to_s.to_sym][object.id][section.to_sym][action.to_sym]
        end
        
        # Персональная политика к ресурсу
        def personal_resources_policies_hash_for_class_of(resource, options = {})
          opts= {
           :hash_name=>'personal_resources_policies_hash',
           :finder=>'PersonalResourcePolicy.find_all_by_user_id_and_resource_type(self.id, resource_class)'
          }
          create_resources_policies_hash_for_class_of(resource, options.merge!(opts))
          @personal_resources_policies_hash
        end
        
        # interfaces
        def personal_resource_policy_exists?(object, section, action, options = {})
          resource_policy_exists(object, section, action, 'personal_resources_policies_hash', options)
        end
        
        def get_personal_resource_policy_hash(object, section, action, options = {})
          get_resource_policy_hash(object, section, action, 'personal_resources_policies_hash', options)
        end
        
        def has_personal_resource_access_for?(object, section, action, options = {})
          opts={ :update_table=>'PersonalResourcePolicy' }
          check_resource_policy(object, section, action, 'personal_resources_policies_hash', options.merge!(opts))
        end
        
        def has_personal_resource_block_for?(object, section, action, options = {})
          opts={ :update_table=>'PersonalResourcePolicy', :return_invert=>true }
          check_resource_policy(object, section, action, 'personal_resources_policies_hash', options.merge!(opts))
        end

        # Групповая политика к ресурсу
        def group_resources_policies_hash_for_class_of(resource, options = {})
          opts= {
           :hash_name=>'group_resources_policies_hash',
           :before_find=>'@group_resources_policies_hash[resource_class.to_sym]= result_hash and return unless self.role',
           :finder=>'GroupResourcePolicy.find_all_by_role_id_and_resource_type(self.role.id, resource_class)'
          }
          create_resources_policies_hash_for_class_of(resource, options.merge!(opts))
          @group_resources_policies_hash
        end
        
        # interfaces
        def group_resource_policy_exists?(object, section, action, options = {})
          resource_policy_exists(object, section, action, 'group_resources_policies_hash', options)
        end
        
        def get_group_resource_policy_hash(object, section, action, options = {})
          get_resource_policy_hash(object, section, action, 'group_resources_policies_hash', options)
        end
        
        def has_group_resource_access_for?(object, section, action, options = {})
          opts={ :update_table=>'GroupResourcePolicy' }
          check_resource_policy(object, section, action, 'group_resources_policies_hash', options.merge!(opts))
        end
        
        def has_group_resource_block_for?(object, section, action, options = {})
          opts={ :update_table=>'GroupResourcePolicy', :return_invert=>true }
          check_resource_policy(object, section, action, 'group_resources_policies_hash', options.merge!(opts))
        end
      end #AbonentMethods
    end# Abonent
  end# Acts
end# Killich