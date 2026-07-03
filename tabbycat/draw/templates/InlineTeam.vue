<template>
  <div class="text-truncate small px-1 inline-team flex-fill d-flex align-items-center hover-target"
       :class="[highlightsCSS, conflictsCSS, hoverConflictsCSS, venueConstraintOutlineCSS]"
       @mouseenter="showHovers" @mouseleave="hideHovers">
    <div :class="[this.isLive ? '' : 'not-live']" v-text="teamName"></div>
    <div class="history-tooltip tooltip" v-if="hasHistory">
      <div :class="['tooltip-inner conflictable', 'hover-histories-' + hasHistory + '-ago']">
        {{ hasHistory }} ago <template v-if="maxOccurrences > 1">× {{ maxOccurrences }}</template>
      </div>
    </div>
  </div>
</template>

<script>
import { mapState } from 'vuex'
import HighlightableMixin from '../../templates/allocations/HighlightableMixin.vue'
import HoverablePanelMixin from '../../templates/allocations/HoverablePanelMixin.vue'
import HoverableConflictMixin from '../../templates/allocations/HoverableConflictMixin.vue'
import HoverableConflictReceiverMixin from '../../templates/allocations/HoverableConflictReceiverMixin.vue'
import ConflictableTeamMixin from '../../templates/allocations/ConflictableTeamMixin.vue'

export default {
  mixins: [HighlightableMixin, HoverablePanelMixin, HoverableConflictMixin, HoverableConflictReceiverMixin, ConflictableTeamMixin],
  props: { team: Object, debateId: Number, isElimination: Boolean },
  methods: {
    showHovers: function () {
      this.showHoverPanel(this.team, 'team')
      this.showHoverConflicts(this.team.id, 'team')
      try {
        const constraints = this.$store.state.extra?.constraints
        const sets = []
        const teamCats = constraints?.teams?.[this.team.id]
        if (teamCats && teamCats.length > 0) { sets.push(teamCats) }
        const instId = this.team.institution
        const instCats = instId ? constraints?.institutions?.[instId] : null
        if (instCats && instCats.length > 0) { sets.push(instCats) }
        this.$store.commit('setHoverVenueConstraints', { allowedSets: sets, debateId: this.debateId })
      } catch (e) { /* noop */ }
    },
    hideHovers: function () {
      this.hideHoverPanel()
      this.hideHoverConflicts()
      this.$store.commit('unsetHoverVenueConstraints')
    },
  },
  computed: {
    teamName: function () {
      let name = this.team.short_name // Default
      if (this.extra.codeNames === 'everywhere' || this.extra.codeNames === 'admin-tooltips-real') {
        name = this.team.code_name
        if (name === '') {
          name = this.gettext('No code name set')
        }
      }
      return name
    },
    clashableType: function () {
      return 'team'
    },
    clashableID: function () {
      return this.team.id
    },
    highlightData: function () {
      return this.team
    },
    hasHistory: function () {
      if (this.hasHoverHistoryConflict) {
        return this.hasHoverHistoryConflict
      } else if (this.hasHistoryConflict) {
        return this.hasHistoryConflict
      }
      return false
    },
    isLive: function () {
      if (this.isElimination || this.team.break_categories.length === 0) {
        return true // Never show strikeouts in out rounds; don't show if no categories are set
      }
      const breakCategoriesCount = this.team.break_categories.length
      let letDeadCategoriesCount = 0
      for (const bc of this.team.break_categories) {
        const category = this.highlights.break.options[bc]
        if (category) {
          if (this.team.points >= category.fields.safe) {
            letDeadCategoriesCount += 1
          }
          if (this.team.points <= category.fields.dead) {
            letDeadCategoriesCount += 1
          }
        }
      }
      return (breakCategoriesCount - letDeadCategoriesCount) > 0
    },
    ...mapState(['extra']),
    assignedVenueCategoryIds: function () {
      try {
        const debate = this.$store.state.debatesOrPanels?.[this.debateId]
        if (!debate || !debate.venue) { return null }
        let venueObj = debate.venue
        if (typeof venueObj === 'number') {
          venueObj = this.$store.state.allocatableItems?.[venueObj]
        }
        const cats = venueObj?.categories ?? null
        if (!cats) { return null }
        return new Set(cats.map(c => (typeof c === 'object' ? c.id : c)))
      } catch (e) { return null }
    },
    teamAllowedSets: function () {
      try {
        const constraints = this.extra?.constraints
        if (!constraints) { return [] }
        const sets = []
        const teamCats = constraints.teams?.[this.team.id]
        if (teamCats && teamCats.length > 0) { sets.push(teamCats) }
        const instId = this.team.institution
        const instCats = instId ? constraints.institutions?.[instId] : null
        if (instCats && instCats.length > 0) { sets.push(instCats) }
        return sets
      } catch (e) { return [] }
    },
    hoveredVenueCategories: function () {
      const cats = this.$store.getters.currentHoverVenueCategories
      if (!cats) { return null }
      return new Set(cats)
    },
    venueConstraintOutlineCSS: function () {
      const sets = this.teamAllowedSets
      if (!sets || sets.length === 0) { return '' }

      const isMismatchForCats = (catSet) => {
        if (!catSet) { return false }
        for (const allowed of sets) {
          let intersects = false
          for (const cid of allowed) { if (catSet.has(cid)) { intersects = true; break } }
          if (!intersects) { return true }
        }
        return false
      }

      if (isMismatchForCats(this.assignedVenueCategoryIds)) {
        return 'conflictable panel-adjudicator'
      }
      if (isMismatchForCats(this.hoveredVenueCategories)) {
        return 'conflictable panel-adjudicator'
      }
      return ''
    },
  },
}
</script>
