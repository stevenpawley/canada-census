import os
import subprocess


class GrassHelper(object):
    def __init__(self, gisbase, gisdbase, location, mapset, epsg):
        self.gisbase = gisbase
        self.gisdbase = gisdbase
        self.location = location
        self.mapset = mapset
        self.epsg = epsg

    def create_location(self):
        try:
            subprocess.run(
                ["grass", os.path.join(
                    self.gisdbase, self.location), 
                    "-c", 
                    f"epsg:{self.epsg}"
                ],
                capture_output=True,
                text=True,
                check=True,
            )
        except subprocess.CalledProcessError as e:
            print(e.stderr)

    def set_python_path(self):
        import sys
        sys.path.append(os.path.join(self.gisbase, "etc", "python"))

    def open_grass_session(self):
        import grass.script as gs
        import grass.jupyter as gj

        return gj.init(
            grass_path=self.gisbase,
            path=self.gisdbase,
            location=self.location,
            mapset=self.mapset,
        )
