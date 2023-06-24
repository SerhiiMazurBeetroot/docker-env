<!DOCTYPE html>
<html>

<head>
  <title>PHP-Server</title>
</head>

<body>
  <h1>Welcome to PHP-Server</h1>

  <a href="/">Home</a><br><br>

  <?php
  if (isset($_POST['submit'])) {
    $name = $_POST['name'];
    $email = $_POST['email'];
  ?>

    <h1>Form Submitted Successfully</h1>
    <p>Thank you for submitting the form!</p>
    <p><?php echo "Name: " . $name; ?></p>
    <p><?php echo "Email: " . $email; ?></p>

  <?php
  } else { ?>
    <form method="POST" action="">
      <label for="name">Name:</label>
      <input type="text" name="name" id="name" required><br><br>

      <label for="email">Email:</label>
      <input type="email" name="email" id="email" required><br><br>

      <input type="submit" name="submit" value="Submit">
    </form>
  <?php }
  ?>

</body>

</html>
