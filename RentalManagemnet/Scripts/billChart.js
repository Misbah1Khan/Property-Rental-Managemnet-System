document.addEventListener("DOMContentLoaded", function () {
    var ctx = document.getElementById('clusteredBarChart').getContext('2d');
    var chart = new Chart(ctx, {
        type: 'bar', // Define the chart type

        data: {
            labels: ['January', 'February', 'March', 'April', 'May', 'June'], // X-axis labels
            datasets: [
                {
                    label: 'Dataset 1',
                    backgroundColor: 'rgba(255, 99, 132, 0.2)',
                    borderColor: 'rgba(255, 99, 132, 1)',
                    borderWidth: 1,
                    data: [12, 19, 3, 5, 2, 3] // Y-axis data
                },
                {
                    label: 'Dataset 2',
                    backgroundColor: 'rgba(54, 162, 235, 0.2)',
                    borderColor: 'rgba(54, 162, 235, 1)',
                    borderWidth: 1,
                    data: [10, 15, 8, 12, 7, 9] // Y-axis data
                },
                {
                    label: 'Dataset 3',
                    backgroundColor: 'rgba(75, 192, 192, 0.2)',
                    borderColor: 'rgba(75, 192, 192, 1)',
                    borderWidth: 1,
                    data: [14, 11, 6, 9, 4, 5] // Y-axis data
                }
            ]
        },

        options: {
            scales: {
                x: {
                    stacked: true
                },
                y: {
                    beginAtZero: true
                }
            }
        }
    });
});