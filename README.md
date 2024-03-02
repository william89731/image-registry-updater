![image_processing20200414-3679-gmvhgp](https://github.com/william89731/image-registry-updater/assets/68069659/1fa65e64-784f-44ed-b2c1-3e6c905c7809)


[![os](https://img.shields.io/badge/os-linux-red)](https://www.linux.org/)
[![script](https://img.shields.io/badge/script-bash-orange)](https://www.gnu.org/software/bash/)
[![docker version](https://img.shields.io/badge/docker%20version-latest-brightgreen)](https://www.docker.com/)
[![license](https://img.shields.io/badge/license-Apache--2.0-yellowgreen)](https://apache.org/licenses/LICENSE-2.0)
[![donate](https://img.shields.io/badge/donate-wango-blue)](https://www.wango.org/donate.aspx)

# Image registry updater

sometimes we use tools to get image update notifications, but then, do we update the images? 

I created this script to find out if our images are actually updated. 

```works in kubernetes and docker```

### usage

launch:

```bash
curl -sSfL https://raw.githubusercontent.com/william89731/image-registry-updater/main/check.sh | bash
```

if you're lucky:

![image](https://github.com/william89731/image-registry-updater/assets/68069659/be716627-b781-4dc7-b735-006e9a17be21)

```note```

use semver tag in yours images. example:

v1.0.0 or 1.0.0




