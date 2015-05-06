# encoding: utf-8
$:.unshift(File.dirname(__FILE__))

require 'nokogiri'
require 'net/http'
require 'json'

module Review2slack
	@@env = ENV['ENV'] || 'development'

	class << self

		attr_accessor :env

		# seul méthode accessible de l'extérieur (tout le reste est en protected)
		def run(*args)
			check_last_review()
		end


		protected

		def check_last_review
			last_review = get_last_review()
			post_to_slack(last_review)
		end


		def get_last_review
			# response = open(ENV['LYDIA_APPSTORE_URL'], :allow_redirections => :all)
			uri = URI.parse('https://itunes.apple.com/fr/app/lydia-paiement-mobile-securise/id575913704')
			req = Net::HTTP.get_response(uri)
			result = Nokogiri::HTML(req.body)

			title = result.css("span.customerReviewTitle").first.content
			content = result.css("p.content").first.content
			rating = result.css("div.rating").first.attributes["aria-label"].content
			userinfo = result.css("span.user-info").first.content.delete!("\n").squeeze(' ').strip

			{title: title, content: content, rating: rating, userinfo: userinfo}
		end


		def post_to_slack(last_review)
			payload = {
				channel: "#produit",
				username: "App Store",
				text: "*#{last_review[:title]}* || #{last_review[:rating]} #{last_review[:userinfo]}\n#{last_review[:content]}",
				icon_emoji: ":star:"
			}

			# uri = URI.parse(ENV['SLACK_URI'])
			uri = URI.parse('https://hooks.slack.com/services/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')
			req = Net::HTTP.post_form(uri, payload: payload.to_json)
		end
	end
end
