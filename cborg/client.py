
class Client:

    def __init__(self, name, email):
        self.name = name
        self.email = email

    def __str__(self):
        return f"Client('{self.name}', '{self.email}')"

    # Add other methods as needed