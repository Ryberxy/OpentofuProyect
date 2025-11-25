# opentofu-libvirt

**OpenTofu** es un *fork* de **Terraform 1.5.x**, creado por la comunidad (liderado por la *Linux Foundation*) después de que HashiCorp cambiara la licencia de Terraform a **BUSL 1.1** en 2023.

OpenTofu conserva el **modelo declarativo de infraestructura como código (IaC)**, totalmente compatible con los ficheros `.tf` y los *providers* existentes de Terraform.

Su objetivo es mantener una herramienta **100 % libre y abierta**, compatible con el ecosistema de Terraform, pero sin restricciones de uso.


## CAMBIOS

### PHPMYADMIN

Funcionamiento:
<img width="1919" height="773" alt="imagen" src="https://github.com/user-attachments/assets/7a488e95-b5c4-419e-af57-fb4cfa58bf31" />

<img width="1919" height="672" alt="imagen" src="https://github.com/user-attachments/assets/15da070b-38b1-4c49-960d-9309fec7d075" />


<img width="1919" height="648" alt="imagen" src="https://github.com/user-attachments/assets/11b24763-b03a-40b2-a646-63adfbdd7210" />


### PHP-FPM REMOTO

La idea es configurar otra máquina que tendrá instalado php-fpm y actuará como servidor de aplicaciones al que serán reenviadas las peticiones de los clientes al servidor web.
Para poder realizar esto en el servidor de aplicaciones debe existir el document root con los archivos .php, al igual que en el servidor web, y la conexión se configurará con un socket tcp en vez de unix.

Para ello he creado una nueva categoría de hosts en el site.yaml, esta se llamará servidores_app y lo he añadido al fichero hosts.
Además he creado un nuevo rol, phpfpm que contiene las variables para configurar el usuario de phpmyadmin y la conexión remota.
También he modificado el fichero de virtualhost de apache, para añadir el socket tcp y el usuario de mariadb ahora permitirá la conexión a la IP 10.0.0.3 que es la del servidor de aplicaciones.

Funcionamiento:
