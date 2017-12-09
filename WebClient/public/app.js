// установки для DateTimePicker
$(function () {
    $('#startTime').datetimepicker({
    	locale: 'ru'
    });
    $('#endTime').datetimepicker({
    	locale: 'ru',
        useCurrent: false
    });
    $("#startTime").on("dp.change", function (e) {
        $('#endTime').data("DateTimePicker").minDate(e.date);
    });
    $("#endTime").on("dp.change", function (e) {
        $('#startTime').data("DateTimePicker").maxDate(e.date);
    });
	$( "#startTime" ).bind( "click", function() {
			$("#optionsPeriod2").click()
	});
	$( "#endTime" ).bind( "click", function() {
			$("#optionsPeriod2").click()
	});
});
