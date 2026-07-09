# We create a class to follow OOP principles
# This class is responsible for generating unique IDs for our system

import uuid

class IdGenerator:

    # @staticmethod means we can call this function without creating an object
    # Example: IdGenerator.generate("cmp")

    @staticmethod
    def generate(prefix: str) ->str:
        """
        Generate a unique ID with a prefix.

        Example outputs:
        cmp_a3f9b2c1   -> complaint
        loc_82f1a9d3   -> location
        img_b21d4c8e   -> image
        """
        # uuid4() generates a random unique identifier
        # .hex converts it into a hexadecimal string
        # [:8] takes only the first 8 characters to keep the ID short
        return f"{prefix}_{uuid.uuid4().hex[:8]}"
        # f-string combines the prefix with the unique part
        # Example: "cmp" + "_" + "a3f9b2c1"
