var app = angular.module('myApp', []);
app.controller('myCtrl', function($scope, $http) {
  $scope.color = '';
  



  $scope.sendColor = function() {
    document.body.style.backgroundColor = "#" + $scope.color;
    
    $http.post('http://127.0.0.1:9090/hello', 5555).then(function(response) {
        
    });
  };
});
