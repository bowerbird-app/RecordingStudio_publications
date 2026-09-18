# frozen_string_literal: true

module RecordingStudioPublications
  module Admin
    PublicationTypeRow = Struct.new(:token, :label, :publications_count, keyword_init: true)

    module TypeRows
      def publication_type_count_cell(row, context)
        inventory = "#{publications_screen_path(context)}?publication_type=#{row.token}"
        linked_cell(row.publications_count.to_s, with_originating_anchor(inventory, context), context)
      end

      def publication_type_rows
        counts = RecordingStudioPublications.publications.reorder(nil).group(:kind).count

        PublicationType::TOKENS.map do |token|
          PublicationTypeRow.new(
            token: token,
            label: PublicationType.parse(token).label,
            publications_count: counts[token].to_i
          )
        end
      end
    end
  end
end
