# opentofu-libvirt

**OpenTofu** es un *fork* de **Terraform 1.5.x**, creado por la comunidad (liderado por la *Linux Foundation*) después de que HashiCorp cambiara la licencia de Terraform a **BUSL 1.1** en 2023.

OpenTofu conserva el **modelo declarativo de infraestructura como código (IaC)**, totalmente compatible con los ficheros `.tf` y los *providers* existentes de Terraform.

Su objetivo es mantener una herramienta **100 % libre y abierta**, compatible con el ecosistema de Terraform, pero sin restricciones de uso.


## CAMBIOS

### PHPMYADMIN
- Creación del rol phpmyadmin
- El rol pertenece a la categoría servidores_web en site.yaml
- Creación y configuración del usuario phpmyadmin en las tareas del rol mariadb
- Creación en group_vars de variables necesarias para la configuración de phpmyadmin
- Modificación del template vhost.j2 del rol apache para utilizar alias de directorio

Funcionamiento:
<img width="1919" height="773" alt="imagen" src="https://github.com/user-attachments/assets/7a488e95-b5c4-419e-af57-fb4cfa58bf31" />

<img width="1919" height="672" alt="imagen" src="https://github.com/user-attachments/assets/15da070b-38b1-4c49-960d-9309fec7d075" />


<img width="1919" height="648" alt="imagen" src="https://github.com/user-attachments/assets/11b24763-b03a-40b2-a646-63adfbdd7210" />


### PHP-FPM REMOTO

La idea es configurar otra máquina que tendrá instalado php-fpm y actuará como servidor de aplicaciones al que serán reenviadas las peticiones de los clientes al servidor web.
Para poder realizar esto en el servidor de aplicaciones debe existir el document root con los archivos .php, al igual que en el servidor web, y la conexión se configurará con un socket tcp en vez de unix.

Para ello he configurado la creación de una nueva máquina en opentofu que será sv_aplicaciones, he tenido que configurarla en el cloud init/server3 y modificar también escenario.tf .
En ansible he creado una nueva categoría de hosts en el site.yaml, esta se llamará servidores_app y lo he añadido al fichero hosts.
Además he creado un nuevo rol, phpfpm que contiene las variables para configurar el usuario de phpmyadmin y la conexión remota.
También he modificado el fichero de virtualhost de apache, para añadir el socket tcp y el usuario de mariadb ahora permitirá la conexión a la IP 10.0.0.3 que es la del servidor de aplicaciones.

Funcionamiento:
<img width="1615" height="634" alt="imagen" src="https://github.com/user-attachments/assets/a67ed5e8-8330-4bb6-affb-9be77e4682b9" />

<img width="1631" height="896" alt="imagen" src="https://github.com/user-attachments/assets/224804df-47df-4b97-808f-69e2b8da6b7a" />

phpmyadmin sigue funcionando, ahora con php-fpm:
<img width="1919" height="601" alt="imagen" src="https://github.com/user-attachments/assets/9e0e0456-999c-4ebb-a32e-85189d4a1de3" />

### ROUTER/NAT
- Creación del rol nat
- iptables persistentes y activar bit de forwarding en tasks/main.yml del rol
- Modificación del rol mariadb, para crear templates y añadir una plantilla de la configuración de red para desactivar la red default
- Igual que mariadb pero en el rol phpfpm
- El rol se ejecutará antes que cualquier otro rol para poder después actualizar e instalar en las demás máquinas
- El rol pertenece a servidores_web en site.yaml

Con esto hemos conseguido suprimir las ips "públicas" en la máquina mariadb y sv_aplicaciones, de modo que se haga snat en apache2 que actuará de router.

Para conectarnos por ssh a mariadb o sv_aplicaciones:
<pre>
  ssh -A debian@ip_apache2
  ssh ubuntu@10.0.0.2
</pre>

<pre>
  ssh -A debian@ip_apache2
  ssh debian@10.0.0.3
</pre>

Funcionamiento:

<img width="794" height="250" alt="imagen" src="https://github.com/user-attachments/assets/ecf03fd0-dd71-488e-9b66-2282935830d5" />

mariadb:
<img width="1057" height="611" alt="imagen" src="https://github.com/user-attachments/assets/889aa6ac-ea14-409e-8155-983ad1f38771" />

sv_aplicaciones:
<img width="1284" height="666" alt="imagen" src="https://github.com/user-attachments/assets/42d816ad-eb94-4075-b305-40ffb73881e5" />

### Wordpress con docker compose en Mariadb10.6
Antes de nada he realizado una instalación manual de wordpress con mariadb y he copiado los volúmenes de docker montados tras la instalación para guardar la configuración de wordpress y mariadb y los he metido en el directorio de ansible comprimidos para que cuando se monte el escenario esté wordpress instalado y funcione correctamente.

- Creación del rol docker-compose
- Creación de templates en docker-compose y hemos copiado el virtualhost del rol apache, al cual he añadido una sección de proxy inverso para poder acceder al wordpress del contenedor docker.
- Adición del módulo proxy_http en el group vars en los módulos de apache2.
- El rol pertenecerá al servidor apache2
- En el rol he utilizado un módulo de la comunidad de docker, ya actualizada a la versión 2, para garantizar la idempotencia sin tener que utilizar command para levantar el escenario con docker-compose.
- Log en wordpress.example.org/wp-admin con el usuario: admin y contraseña: admin.

Hemos realizado esto para poder tener wordpress accesible siendo lanzado desde un contenedor docker que almacena los datos en otro contenedor docker de mariadb, buscando que la instalación de wordpress ya esté realizada y así consigamos nuestro objetivo de forma automática e idempotente.

Funcionamiento:

wordpress.example.org:
<img width="1919" height="986" alt="imagen" src="https://github.com/user-attachments/assets/4e705301-70fc-45d9-b712-4a5209e785c1" />

wordpress.example.org/wp-admin:
<img width="1919" height="1118" alt="imagen" src="https://github.com/user-attachments/assets/e3c06da4-45dc-4652-916a-e1c8677ed687" />


