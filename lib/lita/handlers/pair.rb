require 'rufus-scheduler'

module Lita
  module Handlers
    class Pair < Handler
      config :redis_key, type: String, default: 'lita-pair'

      route(
        /pair add/i,
        :add,
        help: { 'pair add' => 'Put your name in the queue for debugging help.' }
      )

      route(
        /pair schedule/i,
        :schedule,
        help: { 'pair schedule' => 'Configure the pairing frequency' }
      )

      route(
        /pair size/i,
        :size,
        help: { 'pair size' => 'Configure number of people to pair' }
      )

      def add response
        argument = response.args[1].sub(/.*?@/, '')
        user_name = argument || response.user.mention_name
        user = slack_user user_name

        return response.reply('Please use the Slack username') if !user

        room_name = response.message.source.room_object.name

        redis.set key_for_members(room_name), user.id
        redis.lpush key_for_memberships(user.id), room_name

        response.reply "Great, #{user_name} is now in the pairing list for #{room_name}"
      end

      def schedule response # every tuesday at 10am // once today at 10am
        interval = response.args[1].downcase
        day = response.args[2].downcase
        time = response.args[4].downcase
        room_name = response.message.source.room_object.name

        if interval == 'every'
          schedule_every(day, time, room_name)
          response.reply("Pairing has been scheduled #{interval} #{day} at #{time}")
        elsif interval == 'once'
          schedule_once(day, time, room_name)
          response.reply("Pairing has been scheduled for #{day} at #{time}")
        else
          return response.reply("Please use 'once' or 'every'")
        end
      end

      def size response
        number = response.args[1]
        room_name = response.message.source.room_object.name

        redis.set key_for_group_size(room_name), number

        response.reply "Groups of #{number} members in #{room_name} will be paired"
      end

      private

      def schedule_every day, time, room_name
        scheduler = Rufus::Scheduler.new
        weekday = Date.parse(day)
        hour_of_day, minute_of_hour = Time.parse(time).yield_self { |t| [t.hour, t.min ] }

        scheduler.cron("#{minute_of_hour} #{hour_of_day} * * #{weekday}") do
          message_random_users room_name
        end

        scheduler.shutdown
      end

      def schedule_once day, time, room_name
        scheduler = Rufus::Scheduler.new
        time_at = Time.parse("#{day} #{time}")

        scheduler.at time_at do
          message_random_users room_name
        end

        scheduler.shutdown
      end

      def message_random_users room_name
        user_id_groups = group_random_users(room_name)
        user_groups = user_id_groups&.map do |group|
          group&.map { |id| slack_user(id) }
        end

        user_groups.each { |group| Lita::Source.new(user: group) }
      end

      def group_random_users channel
        users = get_users_in_channel(channel).to_a.shuffle
        number = get_group_size_in_channel(channel).to_i
        number_of_groups = users.size / number
        remainder = users.size % number

        groups = users.map do |user|
          new_group = users.pop(number)
          remainder_users = users.size == remainder ? users.size : 0

          new_group.concat(users.pop(remainder_users))
        end

        groups
      end

      def get_users_in_channel channel
        # redis.get key_for_members(channel)
        redis.lrange key_for_members(channel), 0, -1
      end

      def get_group_size_in_channel channel
        redis.get key_for_group_size(channel)
      end

      def slack_user name
        Lita::User.fuzzy_find(name)
        # Lita::Source.new(user: )
      end

      def slack_source_channel room
        Lita::Room.find_by_name(room)
        # Lita::Source.new(room: )
      end

      def key_for_members name
        "#{key_for_redis('members')}:#{name}"
      end

      def key_for_memberships name
        "#{key_for_redis('memberships')}:#{name}"
      end

      def key_for_group_size name
        "#{key_for_redis('grouping')}:#{name}"
      end

      def key_for_room_config name
        "#{key_for_redis('config')}:#{name}"
      end

      def key_for_redis action
        "#{config.redis_key}:#{action}"
      end

      Lita.register_handler(self)
    end
  end
end
