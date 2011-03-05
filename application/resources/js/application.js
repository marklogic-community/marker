$(document).ready(function() {
    $("input.searchbox").blur(function() {
        $(this).css('color', '#CBCBCB');
        if ($(this).value == '') $(this).value = ' Search the site';
    });
    $("input.searchbox").focus(function() {
        if ($(this).value == ' Search the site') $(this).value = '';
        $(this).css('color', 'black');
    });
});
