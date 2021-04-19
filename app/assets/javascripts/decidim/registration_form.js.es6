$(document).ready(() => {
    const $provenanceFieldDiv = $("#registration_user_provenance_field")
    const $provenanceField = $("#registration_user_provenance")

    $("input[name='user[status]'][type='radio']").on("change", (checkedStatus) => {
        const $target = $(checkedStatus.currentTarget)

        if ($target.is(":checked") && !isInRestrictedList($target)) {
            displayOptions($target.val())
            if ($provenanceFieldDiv.hasClass("hide") === true) {
                $provenanceFieldDiv.removeClass('hide')
            }
        } else {
            if ($provenanceFieldDiv.hasClass("hide") === false) {
                $provenanceFieldDiv.addClass('hide')
            }
        }
    })

    const isInRestrictedList = ($target) => {
        return $target.data("provenance") === false
    }

    const displayOptions = (value) => {
        $provenanceField.children("option:not([data-status='" + value + "'])").hide()
        $provenanceField.children("option[data-status='student']").show()
        $provenanceField.children("option[data-status='" + value + "']").show()
    }
});
