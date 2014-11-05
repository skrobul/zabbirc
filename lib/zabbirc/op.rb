module Zabbirc
  class Op

    attr_reader :channels, :setting, :nick
    def initialize zabbix_user: nil, irc_user: nil
      raise ArgumentError, 'zabbix_user' if zabbix_user.nil?
      raise ArgumentError, 'irc_user' if irc_user.nil?
      @nick = zabbix_user.alias
      @zabbix_user = zabbix_user
      @irc_user = irc_user

      @channels = Set.new
      @setting = Setting.new
    end

    def primary_channel
      @channels.find{|c| c.name == @setting.get(:primary_channel) }
    end

    def events_priority
      Priority.new @setting.get(:events_priority)
    end

    def add_channel channel
      @setting.fetch :primary_channel, channel
      @channels << channel
    end

    def remove_channel channel
      @channels.delete channel

      if channel == @setting.get(:primary_channel)
        @setting.set :primary_channel, @channels.first
      end
    end

    def notify event
      return if event.priority < events_priority
      @notified_events ||= {}
      return if @notified_events.key? event.id
      channel = primary_channel
      return unless channel
      channel.send "#{@nick}: #{event.label}"
      @notified_events[event.id] = Time.now
      clear_notified_events
    end
    
    private

    def clear_notified_events
      @notified_events.delete_if do |event_id, timestamp|
        timestamp < (Zabbirc.config.notify_about_events_from_last * 2).seconds.ago
      end
    end
  end
end