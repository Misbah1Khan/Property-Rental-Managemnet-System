/**
 * ---------------------------------------
 * This demo was created using amCharts 5.
 * 
 * For more information visit:
 * https://www.amcharts.com/
 * 
 * Documentation is available at:
 * https://www.amcharts.com/docs/v5/
 * ---------------------------------------
 */

// Define data for each year
var chartData = window.occupancyData;
  var root = am5.Root.new("piechartdiv");
  
  
  root.setThemes([
    am5themes_Animated.new(root)
  ]);
  
  
  var chart = root.container.children.push(am5percent.PieChart.new(root, {
    innerRadius: 135,
      layout: root.verticalLayout,
      radius: am5.percent(40)
  }));
  
  
  var series = chart.series.push(am5percent.PieSeries.new(root, {
    valueField: "size",
    categoryField: "sector"
  }));
    series.get("colors").set("colors", [
        am5.color(0x48F03C),
        am5.color(0xF7F9FA), 
    ]);
  
  
series.data.setAll(chartData);

  series.appear(1000, 100);
  
  
  var label = root.tooltipContainer.children.push(am5.Label.new(root, {
    x: am5.p50,
    y: am5.p50,
    centerX: am5.p50,
    centerY: am5.p50,
    fill: am5.color(0x000000),
    fontSize: 50
  }));
  
  
  var currentYear = 1995;

  label.content("$$$");
  var data = currentYear;
  series.data.setIndex(0, data[0]);
  
  