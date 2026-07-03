<script>
import { mapGetters } from 'vuex'
import ConflictableMixin from './ConflictableMixin.vue'

export default {
  mixins: [ConflictableMixin],
  computed: {
    hasClashConflict: function () {
      const debateAdjudicators = this.allDebatesOrPanels[this.debateId].adjudicators
      const clashes = this.teamClashesForItem(this.team.id)
      if (clashes && 'adjudicator' in clashes) {
        for (const clash of clashes.adjudicator) {
          if (this.isAdjudicatorInPanel(clash.id, debateAdjudicators)) {
            return true
          }
        }
      }
      return false
    },
    hasInstitutionalConflict: function () {
      const debateAdjudicators = this.allDebatesOrPanels[this.debateId].adjudicators
      const clashes = this.teamClashesForItem(this.team.id)
      if (clashes && 'institution' in clashes) {
        for (const clash of clashes.institution) {
          if (this.isInstitutionInPanel(clash.id, debateAdjudicators, null)) {
            return true
          }
        }
      }
      return false
    },
    hasHistoryConflict: function () {
      const debateAdjudicators = this.allDebatesOrPanels[this.debateId].adjudicators
      const histories = this.teamHistoriesForItem(this.team.id)
      let smallestAgo = 99
      if (histories && 'adjudicator' in histories) {
        for (const clash of histories.adjudicator) {
          if (this.isAdjudicatorInPanel(clash.id, debateAdjudicators)) {
            if (clash.ago < smallestAgo) {
              smallestAgo = clash.ago // Want to ensure we show the most recent clash
            }
          }
        }
      }
      if (smallestAgo === 99) {
        return false
      } else {
        return smallestAgo
      }
    },
    maxOccurrences: function () {
      if (this.currentHoverHistories && this.clashableType === 'team') {
        let hoverCount = 0
        if ('team' in this.currentHoverHistories) {
          for (const sourceHistory of this.currentHoverHistories.team) {
            if (sourceHistory.id === this.clashableID) {
              hoverCount += 1
            }
          }
        }
        if (hoverCount > 0) {
          return hoverCount
        }
      }

      if (!(this.debateId && this.team)) {
        return 0
      }

      const histories = this.teamHistoriesForItem(this.team.id)
      if (!histories || !('adjudicator' in histories)) {
        return 0
      }

      const debateAdjudicators = this.allDebatesOrPanels[this.debateId].adjudicators
      const counts = {}
      let maxCount = 0
      for (const history of histories.adjudicator) {
        if (this.isAdjudicatorInPanel(history.id, debateAdjudicators)) {
          counts[history.id] = (counts[history.id] || 0) + 1
          if (counts[history.id] > maxCount) {
            maxCount = counts[history.id]
          }
        }
      }
      return maxCount
    },
    ...mapGetters(['allDebatesOrPanels']),
  },
}
</script>
